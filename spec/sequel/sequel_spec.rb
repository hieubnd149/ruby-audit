require 'spec_helper'

RSpec.describe 'Sequel Model Hook' do
  it 'creates callback' do
    expect(STDOUT).to receive(:puts).with('I am audited')
    create_record
  end
end
