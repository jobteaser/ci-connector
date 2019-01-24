require 'kafka'
require 'socket'
require 'json'
module CI
	class Connector

		attr_accessor :logger

		def initialize(client_id, group_id, bootstrap_servers = 'localhost:9092')
			@client_id = client_id
			@group_id = group_id
			@bootstrap_servers = bootstrap_servers
			@subscribers = {}

			@logger = default_logger
		end

		def default_logger
			logger = Logger.new(STDOUT)
			logger.level = Logger::INFO
			logger
		end

		def on(event, &proc)
			(@subscribers[event] ||= []) << proc
		end

		# from_env return a kafka client from environment variables
		# @return [::CI:Connector]
		def self.from_env
			new(ENV.fetch('KAFKA_CLIENT_ID', Socket.gethostname),
					# By default, use the hostname as consumer group
					ENV.fetch('KAFKA_CONSUMER_GROUP', Socket.gethostname),
					ENV.fetch('KAFKA_BROKERS', 'localhost:9092').split(','))
		end

		# fromEnv is : use from_env
		# @deprecated
		# @return [::CI:Connector]
		def self.fromEnv
			@logger.warn "fromEnv method is deprecated, use from_env"
			self.from_env
		end

		# Start listening for events
		def start

			trap("TERM", &method(:stop))
			trap("INT", &method(:stop))

			kafka = Kafka.new(
				seed_brokers: @bootstrap_servers,
				client_id: @client_id,
				socket_timeout: 20,
				logger: @logger
			)

			@consumer = kafka.consumer(group_id: @group_id)

			@subscribers.each do |key, _|
				@logger.info "Subscribe topic #{key}"
				@consumer.subscribe(key)
			end

			@consumer.each_message do |message|
				@logger.debug message
				begin
					data = JSON.parse message.value
				rescue
					data = :null
					@logger.error "Invalid message #{message.value}"
				end
				if data != :null
					@subscribers[message.topic].each do |subscriber|
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
