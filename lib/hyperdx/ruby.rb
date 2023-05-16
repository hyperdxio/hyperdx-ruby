# frozen_string_literal: true

require "logger"
require "socket"
require "uri"
require_relative "ruby/client"
require_relative "ruby/resources"
require_relative "ruby/version"

module Hyperdx
  class ValidURLRequired < ArgumentError; end

  class MaxLengthExceeded < ArgumentError; end

  class Ruby < ::Logger
    # uncomment line below and line 3 to enforce singleton
    # include Singleton
    Logger::TRACE = 5
    attr_accessor :app, :env, :meta

    def initialize(key, opts = {})
      super(nil, nil, nil)
      @app = opts[:app] || "default"
      @log_level = opts[:level] || "INFO"
      @env = opts[:env]
      @meta = opts[:meta]
      @internal_logger = Logger.new($stdout)
      @internal_logger.level = Logger::DEBUG
      endpoint = opts[:endpoint] || Resources::ENDPOINT
      @hostname = opts[:hostname] || Socket.gethostname

      if @hostname.size > Resources::MAX_INPUT_LENGTH || @app.size > Resources::MAX_INPUT_LENGTH
        @internal_logger.debug("Hostname or Appname is over #{Resources::MAX_INPUT_LENGTH} characters")
        return
      end

      @ip =  opts.key?(:ip) ? opts[:ip] : ""
      @mac = opts.key?(:mac) ? opts[:mac] : ""
      url = "#{endpoint}?hdx_platform=ruby"
      uri = URI(url)

      request = Net::HTTP::Post.new(uri.request_uri, "Content-Type" => "application/json")
      request['Authorization'] = "Bearer #{key}"
      request[:'user-agent'] = opts[:'user-agent'] || "ruby/#{Hyperdx::VERSION}"
      @client = Hyperdx::Client.new(request, uri, opts)
    end

    def default_opts
      {
        app: @app,
        env: @env,
        hostname: @hostname,
        ip: @ip,
        level: @log_level,
        mac: @mac,
        meta: @meta,
      }
    end

    def level
      @log_level
    end

    def level=(value)
      if value.is_a? Numeric
        @log_level = Resources::LOG_LEVELS[value]
        return
      end

      @log_level = value
    end

    def log(message = nil, opts = {})
      if message.nil? && block_given?
        message = yield
      end
      if message.nil?
        @internal_logger.debug("provide either a message or block")
        return
      end
      message = message.to_s.encode("UTF-8")
      @client.write_to_buffer(message, default_opts.merge(opts).merge(
                                         timestamp: (Time.now.to_f * 1000).to_i
                                       ))
    end

    Resources::LOG_LEVELS.each do |lvl|
      name = lvl.downcase

      define_method name do |msg = nil, opts = {}, &block|
        self.log(msg, opts.merge(
                        level: lvl
                      ), &block)
      end

      define_method "#{name}?" do
        return Resources::LOG_LEVELS[self.level] == lvl if level.is_a? Numeric

        self.level == lvl
      end
    end

    def clear
      @app = "default"
      @log_level = "INFO"
      @env = nil
      @meta = nil
    end

    def <<(msg = nil, opts = {})
      log(msg, opts.merge(
                 level: ""
               ))
    end

    def add(*_arg)
      @internal_logger.debug("add not supported in HyperDX logger")
      false
    end

    def unknown(msg = nil, opts = {})
      log(msg, opts.merge(
                 level: "UNKNOWN"
               ))
    end

    def datetime_format(*_arg)
      @internal_logger.debug("datetime_format not supported in HyperDX logger")
      false
    end

    def close
      @client&.exitout
    end
  end
end
