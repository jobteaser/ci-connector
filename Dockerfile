FROM ruby:2.4-alpine

RUN echo @edge http://dl-cdn.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories && \
    echo http://dl-cdn.alpinelinux.org/alpine/edge/main >> /etc/apk/repositories && \
    apk --no-cache add ca-certificates librdkafka@edge==0.11.3-r0

COPY . /usr/src/connector
RUN cd /usr/src/connector && \
    bundle install && \
    gem build ci-connector.gemspec && \
    gem install ci-connector

ENV BOOTSTRAP_SERVERS=localhost \
    TOPIC=github 

ENTRYPOINT [ "/usr/src/app/main.rb" ]