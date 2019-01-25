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
# Slack documentation : https://api.slack.com/docs/messages
# {
#     "text": "Now back in stock!:tada:",
#     "attachments": [
#         {
#             "title": "The Further Adventures of Slackbot",
#             "fields": [
#                 {
#                     "title": "Volume",
#                     "value": "1",
#                     "short": true
#                 },
#                 {
#                     "title": "Issue",
#                     "value": "3",
#             "short": true
#                 }
#             ],
#             "author_name": "Stanford S. Strickland",
#             "author_icon": "http://a.slack-edge.com/7f18https://a.slack-edge.com/a8304/img/api/homepage_custom_integrations-2x.png",
#             "image_url": "http://i.imgur.com/OJkaVOI.jpg?1"
#         },
#         {
#             "title": "Synopsis",
#             "text": "After @episod pushed exciting changes to a devious new branch back in Issue 1, Slackbot notifies @don about an unexpected deploy..."
#         },
#         {
#             "fallback": "Would you recommend it to customers?",
#             "title": "Would you recommend it to customers?",
#             "callback_id": "comic_1234_xyz",
#             "color": "#3AA3E3",
#             "attachment_type": "default",
#             "actions": [
#                 {
#                     "name": "recommend",
#                     "text": "Recommend",
#                     "type": "button",
#                     "value": "recommend"
#                 },
#                 {
#                     "name": "no",
#                     "text": "No",
#                     "type": "button",
#                     "value": "bad"
#                 }
#             ]
#         }
#     ]
# }

conn = CI::Connector.from_env
conn.on('environment.lifecycle') do |event|
  if event['event'] == 'release_completed'

    uri = URI("https://hooks.slack.com/services/T03AA3Y27/BFP2H3YV9/" + ENV['SLACK_TOKEN'])

    header = {
      'Content-Type': 'application/json',
    }

    payload = {
      text: "Release #{event['data']['project']['name']} #{event['data']['name']}",
      "attachments": [
        {
          "color": "#36a64f",
          "title": "Release completed",
          "ts": DateTime.iso8601(date).to_time.to_i,
          "fields": [
            {
              "title": "Project",
              "value": event['data']['project']['name'],
              "short": flase
            },
            {
              "title": "Release",
              "value": event['data']['name'],
              "short": false
            },
            {
              "title": "Commit",
              "value": event['data']['commitId'],
              "short": false
            }
          ]
        }
      ]
    }

    # Create the HTTP objects
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri, header)
    puts payload.to_json
    request.body = payload.to_json

    # Send the request
    http.request(request)
  end
end

conn.start
