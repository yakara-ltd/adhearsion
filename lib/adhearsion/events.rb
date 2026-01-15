# encoding: utf-8

require 'has_guarded_handlers'
require 'singleton'
require 'celluloid'

module Adhearsion
  module Events

    class Handler
      include HasGuardedHandlers
      include Singleton

      def call_handler(handler, guards, event)
        super
        throw :pass
      end

      alias :register_callback :register_handler

      def method_missing(method_name, *args, &block)
        register_handler method_name, *args, &block
      end

      def respond_to_missing?(method_name, include_private = false)
        true
      end
    end

    class Worker
      include Celluloid

      def work(type, object)
        Handler.instance.trigger_handler type, object
      rescue => e
        raise if type == :exception
        async.work :exception, e
      end
    end

    class WorkerPool
      def initialize(size)
        @workers = size.times.map { Worker.new }
        @index = 0
        @mutex = Mutex.new
      end

      def async
        self
      end

      def work(type, object)
        worker = @mutex.synchronize do
          w = @workers[@index]
          @index = (@index + 1) % @workers.size
          w
        end
        worker.async.work(type, object)
      end

      def work_sync(type, object)
        worker = @mutex.synchronize do
          w = @workers[@index]
          @index = (@index + 1) % @workers.size
          w
        end
        worker.work(type, object)
      end

      def alive?
        @workers.any?(&:alive?)
      end
    end

    class << self
      @mutex = Mutex.new

      def synchronize(&block)
        @mutex.synchronize(&block)
      end

      def method_missing(method_name, *args, &block)
        Handler.instance.send method_name, *args, &block
      end

      def respond_to_missing?(method_name, include_private = false)
        Handler.instance.respond_to? method_name, include_private
      end

      def trigger(type, object = nil)
        queue.async.work type, object
      end

      def trigger_immediately(type, object = nil)
        queue.work_sync type, object
      end

      def draw(&block)
        Handler.instance.instance_exec(&block)
      end

      def queue
        synchronize do
          unless @queue && @queue.alive?
            init
          end

          @queue
        end
      end

      def init
        size = Adhearsion.config.core.event_threads
        logger.debug "Initializing event worker pool of size #{size}"
        @queue = WorkerPool.new(size)
      end

      def refresh!
        synchronize do
          clear_without_lock
          init
        end
      end

      def clear
        synchronize do
          clear_without_lock
        end
      end

      private

      def clear_without_lock
        @queue = nil
        Handler.instance.clear_handlers
      end
    end

  end
end
