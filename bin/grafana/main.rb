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
#     "name: "release v_2019-01-22_13-29-18_1f7c8b53",
#     "data": [
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
# Grafana documentation : http://docs.grafana.org/http_api/annotations/
# {
#   "dashboardId":468,
#   "panelId":1,
#   "time":1507037197339,
#   "isRegion":true,
#   "timeEnd":1507180805056,
#   "tags":["tag1","tag2"],
#   "text":"Annotation Description"
# }


def iso_to_millis(date)
  (DateTime.iso8601(date).to_time.to_f * 1000).to_i
end

conn = CI::Connector.from_env
conn.on('environment.lifecycle') do |event|
  if event['event'] == 'release_completed'

    uri = URI("https://grafana.prod.jobteaser.net/api/annotations")

    header = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + ENV['GRAFANA_TOKEN']
    }

    payload = {
      time: iso_to_millis(event['data']['start']),
      timeEnd: iso_to_millis(event['data']['end']),
      isRegion: true,
      tags: [ 
        "release", 
        "app:#{event['data']['projet']['name']}"
      ],
      text: "Release #{event['data']['project']['name']} #{event['name']}"
    }

    # Create the HTTP objects
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri, header)
    puts payload.to_json
    request.body = payload.to_json

    # Send the request
    response = http.request(request)
    end
end

conn.start

trap("TERM") { conn.stop }
trap("INT") { conn.stop }