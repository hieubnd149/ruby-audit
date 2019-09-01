# frozen_string_literal: true

module RubyAudit
  class Auditor
    def self.call(klass, *events)
      new(klass, events).setup
    end

    def initialize(klass, *events)
      @klass = klass
      @events = events
    end

    def setup
      @events.each do |event|
        RubyAudit::DSL::Injector.inject_callback(@klass, event)
      end
    end
  end
end
