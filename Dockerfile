FROM ruby:2.4-alpine

RUN apk --no-cache add ca-certificates 

COPY . /usr/src/connector
RUN cd /usr/src/connector && \
    bundle install && \
    gem build ci-connector.gemspec && \
    gem install ci-connector

ENV BOOTSTRAP_SERVERS=localhost \
    TOPIC=github 
