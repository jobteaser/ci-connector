require 'kafka'
require 'socket'
require 'json'
module CI
  class Connector

    attr_accessor :logger

    def initialize(client_id, group_id, bootstrap_servers = 'localhost:9092', topic = 'github')
      @client_id = client_id
      @group_id = group_id
      @topic = topic
      @bootstrap_servers = bootstrap_servers
      @subscribers = Hash.new([])

      @logger = defaultLogger
    end

    def defaultLogger
      logger = Logger.new(STDOUT)
      logger.level = Logger::INFO
      logger
    end

    def on(event, &proc)
      @subscribers[event] << proc
    end

    def self.from_env
      new(ENV.fetch('KAFKA_CLIENT_ID', Socket.gethostname),
          # By default, use the hostname as consumer group
          ENV.fetch('KAFKA_CONSUMER_GROUP', Socket.gethostname),
          ENV.fetch('KAFKA_BROKERS', 'localhost:9092').split(','),
          ENV.fetch('KAFKA_TOPIC', 'github'))
    end

    # Start listening for events
    def start
      kafka = Kafka.new(
        seed_brokers: @bootstrap_servers,
        client_id: @client_id,
        socket_timeout: 20,
        logger: @logger
      )

      @consumer = kafka.consumer(group_id: @group_id)
      @consumer.subscribe(@topic)

      @consumer.each_message do |message|
        data = JSON.parse message.value

        @logger.debug data
        if @subscribers[data['type']].respond_to?('each')
          @subscribers[data['type']].each do |subscriber|
            subscriber.call data
          end
        end
      end
    end

    def stop
      @consumer.stop
    end

  end
end
