# frozen_string_literal: true

require "minitest/autorun"

require_relative "../lib/hyperdx/ruby"
require_relative "../lib/hyperdx/ruby/client"
require_relative "test_server"

class TestHyperDXRuby < Minitest::Test
  LOG_LINE = "log line"

  def get_options(port)
    {
      hostname: "rubyTestHost",
      ip: "75.10.4.81",
      mac: "00:00:00:a1:2b:cc",
      app: "rubyApplication",
      level: "INFO",
      env: "PRODUCTION",
      endpoint: "http://localhost:#{port}",
      flush_interval: 1,
      flush_size: 5,
      retry_timeout: 1
    }
  end

  def log_level_test(level, port, expected_level)
    options = get_options(port)
    hyperdx_thread = Thread.start do
      logger = Hyperdx::Ruby.new("pp", options)
      logger.send(level, LOG_LINE)
    end

    server_thread = Thread.start do
      server_generator = TestServer.new
      server = server_generator.start_server(port)
      recieved_data = server_generator.accept_logs_and_respond(server, "HTTP/1.1 200 OK")

      assert_equal(recieved_data[0][:message], LOG_LINE)
      assert_equal(recieved_data[0][:app], options[:app])
      assert_equal(recieved_data[0][:level], expected_level)
      assert_equal(recieved_data[0][:env], options[:env])
    end

    assert hyperdx_thread.join(10), "HyperDX thread timeout for port #{port}"
    assert server_thread.join(10), "Server thread timeout for port #{port}"
  end

  # Should retry to connect and preserve the failed line
  def retry_test(level, port, _expected_level)
    second_line = " second line"
    options = get_options(port)

    logger = Hyperdx::Ruby.new("pp", options)
    logger.send(level, LOG_LINE)

    server_thread = Thread.start do
      server_generator = TestServer.new
      server = server_generator.start_server(port)
      server_generator.accept_logs_and_respond(server, "HTTP/1.1 408 Request Timeout")
      # make a second request
      logger.send(level, second_line)

      # Both lines will come back in separate requests
      recieved_data1 = server_generator.accept_logs_and_respond(server, "HTTP/1.1 200 OK")
      recieved_data2 = server_generator.accept_logs_and_respond(server, "HTTP/1.1 200 OK")

      # The order of recieved lines is unpredictable.
      assert_includes([recieved_data1[0][:message], recieved_data2[0][:message]], LOG_LINE)
      assert_includes([recieved_data1[0][:message], recieved_data2[0][:message]], second_line)
    end

    assert server_thread.join(10), "Server thread timeout for retry test"
  end

  def test_all
    log_level_test("warn", 2000, "WARN")
    log_level_test("info", 2001, "INFO")
    log_level_test("fatal", 2002, "FATAL")
    log_level_test("debug", 2003, "DEBUG")
    retry_test("fatal", 2004, "FATAL")
  end
end
