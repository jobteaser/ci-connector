# Ci::Connector

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/ci/connector`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ci-connector'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ci-connector

## Usage

### Using the docker image

Sample script

./main.rb

```ruby
#!/usr/bin/env ruby

require  "CI/connector"

conn = CI::Connector.fromEnv()
conn.onPullRequestClosed do |event|
   conn.logger.info "Close PR #{event['number']}"
end

trap("TERM") { conn.stop }
trap("INT") { conn.stop }

conn.start
```

Minimal Dockerfile

./Dockerfile

```Dockerfile
FROM docker.k8s.jobteaser.net/coretech/ci-connector:<TAG>
COPY main.rb /usr/src/app/main.rb
```

```bash
export KAFKA_BROKERS=<kafka>
export KAFKA_CONSUMER_GROUP=<groupname>

docker run -d -e KAFKA_BROKERS -e KAFKA_CONSUMER_GROUP <image_name>
```