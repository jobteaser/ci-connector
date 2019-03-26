require 'net/http'
require 'uri'
require 'json'
require "CI/connector"
require 'date'

# Event format
# https://jobteaser.atlassian.net/wiki/spaces/TS/pages/306643015/Environment+lifecycle
# {
#     "event"   : "release_completed",
#     "type"    : "release",
#     "date"    : "2019-01-21T10:19:23+0000",
#     "producer": "jenkins",
#     "data": [
#         "project"  : [
#             "namespace": "career-services",
#             "name"     : "talent_bank
#             "branch"   : "master"
#         ],
#         "commitId" : "02cfb31770e081165ea1db43209b13e2f636b09b",
#         "name: "release v_2019-01-22_13-29-18_1f7c8b53",
#         "changelog": [],
#         "start": "2019-01-21T10:19:18+0000"
#         "end"  : "2019-01-21T10:19:23+0000"
#     ]
# }
#
# Datadog documentation : https://docs.datadoghq.com/api/?lang=ruby#post-an-event
# ARGUMENTS
#
# - title [required]:
#     The event title. Limited to 100 characters.
# - text [required]:
#     The body of the event. Limited to 4000 characters.
#     The text supports markdown. Use msg_text with the Datadog Ruby library
# - date_happened [optional, default = now]:
#     POSIX timestamp of the event. Must be sent as an integer (i.e. no quotes).
#     Limited to events no older than 1 year, 24 days (389 days)
# - priority [optional, default = normal]:
#     The priority of the event: normal or low.
# - host [optional, default=None]:
#     Host name to associate with the event. Any tags associated with the host are also applied to this event.
# - tags [optional, default=None]:
#     A list of tags to apply to the event.
# - alert_type [optional, default = info]:
#     If it’s an alert event, set its type between: error, warning, info, and success.
# - aggregation_key [optional, default=None]:
#     An arbitrary string to use for aggregation. Limited to 100 characters.
#     If you specify a key, all events using that key are grouped together in the Event Stream.
# - source_type_name [optional, default=None]:
#     The type of event being posted.
# - Options: nagios, hudson, jenkins, my_apps, chef, puppet, git, bitbucket…
#     Complete list of source attribute values

def iso_to_millis(date)
  DateTime.iso8601(date).to_time.to_i
end

conn = CI::Connector.from_env
conn.on('environment.lifecycle') do |event|
  if event['event'] == 'release_completed'

    uri = URI("https://api.datadoghq.com/api/v1/events?api_key=" + ENV['DDAGENT_TOKEN'])

    payload = {
      date_happened: iso_to_millis(event['data']['end']),
      tags: [
        "release",
        "app:#{event['data']['project']['name']}",
        "namespace:#{event['data']['project']['namespace']}",
        "branch:#{event['data']['project']['branch']}",
        "sha1:#{event['data']['commitId']}",
        "name:#{event['data']['name']}"
      ],
      title: "Release #{event['data']['project']['name']} #{event['name']}",
      text: "Release #{event['data']['project']['name']} #{event['name']} started at #{event['data']['start']} and finished at #{event['data']['end']}\nChangelog: #{event['data']['changelog']}",
      alert_type: "info",
      aggregation_key: "Releases",
      source_type_name: "JENKINS"
    }

    # Create the HTTP objects
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = payload.to_json

    # Send the request
    response = http.request(request)

    case response
    when Net::HTTPSuccess, Net::HTTPRedirection
      puts "#{response.code}: #{response.body if response.class.body_permitted? && !response.body.nil?}"
    else
      puts "#{response.code}: #{response.body if response.class.body_permitted? && !response.body.nil?}\n#{request.body}"
    end

  end
end

conn.start

trap("TERM") {conn.stop}
trap("INT") {conn.stop}
