# frozen_string_literal: true

module RubyAudit
  module DSL
    module Injector
      def self.inject_callback(klass, event)
        callback_method = "after_#{event}".to_sym
        processor_method = inject_audit_processor(klass, callback_method)

        inject_callback_method(klass, callback_method, processor_method)
      end

      private

      def self.inject_audit_processor(klass, callback_name)
        method_name = "_process_#{callback_name}".to_sym

        unless klass.respond_to?(method_name)
          klass.class_eval <<-EORUBY, __FILE__, __LINE__ + 1
            def #{method_name}
              RubyAudit::Processor.execute
            end
          EORUBY
        end
        method_name
      end

      def self.inject_callback_method(klass, callback, process_method)
        if klass.respond_to?(callback)
          klass.class_eval <<-EORUBY, __FILE__, __LINE__ + 1
            def _new_#{callback}
              #{processor_method}
              super
            end
            alias_method :_old_#{callback}, :#{callback}
            alias_method :#{callback}, :_new_#{callback}
          EORUBY
        else
          klass.class_eval <<-EORUBY, __FILE__, __LINE__ + 1
            def #{callback}
              #{processor_method}
              super
            end
          EORUBY
        end
      end
    end
  end
end
