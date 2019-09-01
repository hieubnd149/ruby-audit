# frozen_string_literal: true

module RubyAudit
  module Audited
    def audit(*actions)
      RubyAudit::Auditor.call(self, actions)
    end
  end
end
