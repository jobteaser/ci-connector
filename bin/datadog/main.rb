require 'net/http'
require 'uri'
require 'json'
require "CI/connector"
require 'date'


conn = CI::Connector.from_env()
conn.on('environment.lifecycle') do |event|
  if event['type'] == 'release'

    uri = URI("https://api.datadoghq.com/api/v1/events?api_key=" + ENV['DDAGENT_TOKEN'])

    payload = {
        date_happened: (DateTime.iso8601(event['date']).to_time).to_i,
        tags: [
            "release",
            "app:#{event['project']['name']}"
        ],
        text: "Release #{event['project']['name']} #{event['name']}",
        title: "Release #{event['project']['name']} #{event['name']}",
        alert_type: "info",
    }

    # Create the HTTP objects
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri)
    puts payload.to_json
    request.body = payload.to_json

    # Send the request
    response = http.request(request)
  end
end

conn.start

trap("TERM") {conn.stop}
trap("INT") {conn.stop}
