require "kafka"
require "socket"

module CI

class Connector

    def initialize(client_id, group_id, bootstrap_servers = 'localhost:9092', topic = 'github' )
        @client_id = client_id
        @group_id = group_id
        @topic = topic
        @bootstrap_servers = bootstrap_servers
        @subscribers = {}
    end

    def on(event,&proc)
        ( subscribers[event] ||= [] ) << proc
    end

    def self.fromEnv
        self.new(
            client_id: ENV.fetch("KAFKA_CLIENT_ID",Socket.gethostname),
            # By default, use the hostname as consumer group
            group_id: ENV.fetch("KAFKA_CONSUMER_GROUP",Socket.gethostname)
            bootstrap_servers:  ENV.fetch("KAFKA_BROKERS","localhost:9092").split(","),
            topic: ENV.fetch("KAFKA_TOPIC","github"),
           )
    end

    # Start listening for events
    def start

        logger = Logger.new(STDOUT)

        kafka = Kafka.new(
            seed_brokers: @bootstrap_servers,
            client_id: @client_id,
            socket_timeout: 20,
            logger: logger,
        )

        consumer = kafka.consumer(group_id: @group_id)
        consumer.subscribe(topic)

        consumer.each_message(topic: topic) do |message|
            subscribers[message['type']].each do |subscriber|
                subscriber.call message
            end
        end

    end

end

end