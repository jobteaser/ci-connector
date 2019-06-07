# Event format
# https://jobteaser.atlassian.net/wiki/spaces/TS/pages/306643015/Environment+lifecycle
# {
#     "event"   : "release_completed",
#     "type"    : "release",
#     "date"    : "2019-01-21T10:19:23+0000",
#     "producer": "jenkins",
#     "data": [
#         "name: "release v_2019-01-22_13-29-18_1f7c8b53",
#         "project"  : [
#             "namespace": "career-services",
#             "name"     : "talent_bank
#             "branch"   : "master"
#         ],
#         "commitId" : "02cfb31770e081165ea1db43209b13e2f636b09b",
#         "changelog": [],
#         "start": "2019-01-21T10:19:18+0000"
#         "end"  : "2019-01-21T10:19:23+0000"
#     ]
# }
#

require 'CI/connector'
require 'net/smtp'

# Encloses git command
module GitCommand
  CURRENT_TAG_CMD = "git tag | grep -i 'release-' | sort -r | sed -n '1p'".freeze
  PREVIOUS_TAG_CMD = "git tag | grep -i 'release-' | sort -r | sed -n '2p'".freeze

  def self.clone!(project_name)
    %x(git clone --bare https://#{ENV.fetch('GITHUB_TOKEN')}@github.com/jobteaser/#{project_name}.git)
  end

  def self.config!
    %x(git config --global user.name "ci-connector-release-notification")
    %x(git config --global user.email "dev@jobteaser.com")
  end

  def self.fetch!
    %x(git fetch origin '+refs/heads/*:refs/heads/*' --prune)
  end

  def self.add_tag!(commit_id)
    %x(git tag -a release-`date +'%Y-%m-%d-%H%M%S'` #{commit_id} -m release-`date +'%Y-%m-%d-%H%M%S'`)
    %x(git push origin --tags)
  end

  def self.stat
    %x(git diff --stat `#{PREVIOUS_TAG_CMD}`)
  end

  def self.log
    %x(git log --pretty=format:'%B' `#{CURRENT_TAG_CMD}`...`#{PREVIOUS_TAG_CMD}`)
  end

  def self.commits_count
    %x(git log --pretty=oneline `#{CURRENT_TAG_CMD}`...`#{PREVIOUS_TAG_CMD}` | wc -l)
  end

  def self.current_tag
    `#{CURRENT_TAG_CMD}`
  end
end

class SendReleaseEmail

  FROM_ADDRESS = 'dev@jobteaser.com'.freeze

  TO_ADDRESSES = {
    'jobcrawler' => %w(
    tribe-talent-acquisition@jobteaser.com
    ),
    'release_notification' => %w(
    sacha.alhimdani@jobteaser.com
    ),
    'jobteaser' => %w(
    release-notifications@jobteaser.com
    )
  }.freeze

  def initialize(project_name:)
    @project_name = project_name
    @to_addresses = TO_ADDRESSES[@project_name]
  end

  def run
    Net::SMTP.start(
      ENV.fetch('SMTP_ADDRESS'),
      ENV.fetch('SMTP_PORT'),
      ENV.fetch('SMTP_DOMAIN'),
      ENV.fetch('SMTP_USER_NAME'),
      ENV.fetch('SMTP_PASSWORD'),
      ENV.fetch('SMTP_AUTH')
      ) do |smtp|
      smtp.send_message release_email, FROM_ADDRESS, @to_addresses
    end
  end

  private

  def release_email
    <<~HEREDOC
    From: <#{FROM_ADDRESS}>
    MIME-Version: 1.0
    Content-type: text/html
    To: <#{@to_addresses.join('>,<')}>
    Subject: #{@project_name} - #{GitCommand.current_tag}

    This mail contains all ticket(s) merged since last release:
    #{translations_log}
    #{formated_logs}
    #{formated_git_commits_count}
    HEREDOC
  end

  def translations_log
    return unless GitCommand.log[/Updated translations from PhraseApp/]

    '<p>* New translations from PhraseApp<p>'
  end

  def formated_logs
    GitCommand.log.to_s.lines.map { |log| FixesLog.new(log) }.reject { |fl| fl.message.nil? }.
    sort.map(&:to_s).uniq.join("\n")
  end

  def formated_git_commits_count
    "<p>We merged #{GitCommand.commits_count.strip} commit(s) since last release.</p>"
  end

  # Display message from fixes tag.
  class FixesLog

    FIXES_LINE_REGEX = Regexp.new('^ *(?:fixes|closes) *:? *(?<line>.*)', true)
    FIXES_LINK_REGEX = Regexp.new('(?<link>https?://.*) *$')

    attr_reader :message, :link

    def initialize(log)
      return unless log =~ FIXES_LINE_REGEX

      @link = FIXES_LINK_REGEX.match(log)&.[](:link)
      @message = FIXES_LINE_REGEX.match(log)[:line].gsub(@link.to_s, '').gsub(/- *$/, '').strip
    end

    def <=>(other)
      message.to_s <=> other.message.to_s
    end

    def to_s
      return "<p>* <a href='#{link}'>#{message}</a></p>" if link

      "<p>* #{message}</p>"
    end

  end
  private_constant :FixesLog
end

GitCommand.clone!('jobcrawler')
GitCommand.clone!('jobteaser')
GitCommand.config!

conn = CI::Connector.from_env
conn.on('environment.lifecycle') do |event|
  if event['event'] == 'release_completed'
    project_name = event['data']['project']['name']

    if %w(jobcrawler jobteaser).include?(project_name)
      Dir.chdir("#{project_name}.git") do
        GitCommand.fetch!
        GitCommand.add_tag!(event['data']['commitId'])

        SendReleaseEmail.new(project_name: project_name).run
      end
    end

  end
end

conn.start
