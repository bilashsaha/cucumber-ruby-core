# frozen_string_literal: true
require 'gherkin/gherkin'

module Cucumber
  module Core
    module Gherkin
      ParseError = Class.new(StandardError)

      class Parser
        attr_reader :receiver, :event_bus
        private     :receiver, :event_bus

        def initialize(receiver, event_bus)
          @receiver = receiver
          @event_bus = event_bus
        end

        def document(document)
          parser = ::Gherkin::Gherkin.new(
            [],               # do not pass paths
            false,            # no source messages
            true,             # ast messages
            true,             # pickles messages
            document.language # the default dialect
          )

          begin
            messages = parser.parse(document.uri, document.body)
            messages.each do |message|
              if !message.gherkinDocument.nil?
                event_bus.gherkin_source_parsed(message.gherkinDocument.to_hash)
              elsif !message.pickle.nil?
                receiver.pickle(message.pickle.to_hash)
              elsif !message.attachment.nil?
                raise message.attachment.data
              else
                raise "Unknown message: #{message.to_hash}"
              end
            end
          rescue RuntimeError => e
            raise Core::Gherkin::ParseError.new("#{document.uri}: #{e.message}")
          end
        end

        def done
          receiver.done
          self
        end
      end
    end
  end
end
