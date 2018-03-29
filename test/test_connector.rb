#!/usr/bin/env ruby

lib = File.expand_path("../../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "CI/connector"

conn = CI::Connector.from_env()
conn.on('github.pull_request') do |event|
  if event['action'] == 'closed'
    conn.logger.info "Close PR #{event['number']}"
  end
end

trap("TERM") { conn.stop }
trap("INT") { conn.stop }

conn.start
