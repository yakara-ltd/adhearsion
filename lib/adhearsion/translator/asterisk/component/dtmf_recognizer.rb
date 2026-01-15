# encoding: utf-8

require 'ruby_speech'
require 'singleton'
require 'concurrent'
require 'adhearsion/translator/asterisk/component'

module Adhearsion
  module Translator
    class Asterisk
      module Component
        class DTMFRecognizer
          class BuiltinMatcherCache
            include Singleton
            include MonitorMixin

            def get(uri)
              synchronize { cache[uri] ||= fetch(uri) }
            end

            private

            def fetch(uri)
              grammar = RubySpeech::GRXML.from_uri(uri)
              RubySpeech::GRXML::Matcher.new(grammar)
            end

            def cache
              @cache ||= {}
            end
          end

          def initialize(responder, grammar, initial_timeout = nil, inter_digit_timeout = nil, terminator = nil)
            @responder = responder
            @mutex = Mutex.new
            @finished = Concurrent::AtomicBoolean.new(false)

            self.initial_timeout = initial_timeout || -1
            self.inter_digit_timeout = inter_digit_timeout || -1
            @terminator = terminator

            @matcher = if grammar.url
              BuiltinMatcherCache.instance.get(grammar.url)
            else
              RubySpeech::GRXML::Matcher.new RubySpeech::GRXML.import(grammar.value.to_s)
            end
            @buffer = ""
          end

          def <<(digit)
            callback = nil
            @mutex.synchronize do
              return if @finished.true?
              cancel_initial_timer_locked
              @buffer << digit unless terminating?(digit)
              case (match = get_match)
              when RubySpeech::GRXML::NoMatch
                callback = finalize_locked(:nomatch)
              when RubySpeech::GRXML::MaxMatch
                callback = finalize_locked(:match, match)
              when RubySpeech::GRXML::Match
                callback = finalize_locked(:match, match) if terminating?(digit)
              when RubySpeech::GRXML::PotentialMatch
                callback = finalize_locked(:nomatch) if terminating?(digit)
              end
              reset_inter_digit_timer_locked unless @finished.true?
            end
            # Call responder outside mutex to avoid deadlocks
            callback&.call
          end

          def start_timers
            @mutex.synchronize do
              begin_initial_timer_locked(@initial_timeout / 1000.0) unless @initial_timeout == -1
            end
          end

          # Lock-free check - safe to call from any thread
          def alive?
            !@finished.true?
          end

          private

          def terminating?(digit)
            digit == @terminator
          end

          def get_match
            @matcher.match @buffer.dup
          end

          def initial_timeout=(other)
            raise OptionError, 'An initial timeout value that is negative (and not -1) is invalid.' if other < -1
            @initial_timeout = other
          end

          def inter_digit_timeout=(other)
            raise OptionError, 'An inter-digit timeout value that is negative (and not -1) is invalid.' if other < -1
            @inter_digit_timeout = other
          end

          def begin_initial_timer_locked(timeout)
            @initial_timer = Concurrent::ScheduledTask.execute(timeout) do
              callback = nil
              @mutex.synchronize do
                next if @finished.true?
                callback = finalize_locked(:noinput)
              end
              callback&.call
            end
          end

          def cancel_initial_timer_locked
            return unless @initial_timer
            @initial_timer.cancel
            @initial_timer = nil
          end

          def reset_inter_digit_timer_locked
            return if @inter_digit_timeout == -1
            cancel_inter_digit_timer_locked
            @inter_digit_timer = Concurrent::ScheduledTask.execute(@inter_digit_timeout / 1000.0) do
              callback = nil
              @mutex.synchronize do
                next if @finished.true?
                case (match = get_match)
                when RubySpeech::GRXML::Match
                  callback = finalize_locked(:match, match)
                else
                  callback = finalize_locked(:nomatch)
                end
              end
              callback&.call
            end
          end

          def cancel_inter_digit_timer_locked
            return unless @inter_digit_timer
            @inter_digit_timer.cancel
            @inter_digit_timer = nil
          end

          # Returns a callback proc to be executed outside the mutex
          def finalize_locked(match_type, match = nil)
            cancel_initial_timer_locked
            cancel_inter_digit_timer_locked
            @finished.make_true
            # Return a proc to call outside the mutex
            if match
              -> { @responder.send(match_type, match) }
            else
              -> { @responder.send(match_type) }
            end
          end
        end
      end
    end
  end
end
