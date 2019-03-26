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
# REQUEST EXAMPLE
#
# curl -X POST 'https://api.newrelic.com/v2/applications/${APP_ID}/deployments.json' \
#      -H 'X-Api-Key:${APIKEY}' -i \
#      -H 'Content-Type: application/json' \
#      -d \
# '{
#   "deployment": {
#     "revision": "REVISION",
#     "changelog": "Added: /v2/deployments.rb, Removed: None",
#     "description": "Added a deployments resource to the v2 API",
#     "user": "datanerd@example.com"
#   }
# }'
# https://docs.newrelic.com/docs/apm/new-relic-apm/maintenance/record-deployments#deployment_limits
# Parameter 	Data Type 	Description
# revision 	(String, 127 character maximum) 	Required. A unique ID for this deployment, visible in the Overview page and on the Deployments page. Can be any string, but is usually a version number or a Git checksum.
# changelog 	(String, 65535 character maximum) 	Optional. A summary of what changed in this deployment, visible in the Deployments page when you select (selected deployment) > Change log.
# description 	(String, 65535 character maximum) 	Optional. A high-level description of this deployment, visible in the Overview page and on the Deployments page when you select an individual deployment.
# user 	(String, 31 character maximum) 	Optional. A username to associate with the deployment, visible in the Overview page and on the Deployments page.

def iso_to_millis(date)
  DateTime.iso8601(date).to_time.to_i
end

conn = CI::Connector.from_env
conn.on('environment.lifecycle') do |event|
  if event['event'] == 'release_completed'

    uri = URI("https://api.newrelic.com/v2/applications/" + ENV['NEWRELIC_APP_ID'] + "/deployments.json")

    header = {
      'Content-Type': 'application/json',
      'Authorization': 'x-api-key ' + ENV['NEWRELIC_TOKEN']
    }

    payload = {
      deployment: {
        revision: "#{event['data']['name']}",
        changelog: "Release #{event['data']['project']['name']} #{event['name']} started at #{event['data']['start']} and finished at #{event['data']['end']}\nSha1: #{event['data']['commitId']}\nChangelog: #{event['data']['changelog']}",
        "description": "Release #{event['data']['project']['name']} #{event['name']}",
      }
    }

    # Create the HTTP objects
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri, header)
    # puts payload.to_json
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
