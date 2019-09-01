require 'spec_helper'

RSpec.describe 'Sequel Model Hook' do
  class ABC
    extend RubyAudit::Audited

    byebug
    audit :create, :update, :destroy
    byebug
  end

  it do
    expect(true).to be true
  end
end
