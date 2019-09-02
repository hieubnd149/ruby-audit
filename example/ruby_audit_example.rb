# Loading the app
root_path = File.expand_path('../../', __FILE__)
$LOAD_PATH.unshift(root_path) unless $LOAD_PATH.include?(root_path)

ENV['APP_ENV'] = 'test'

require 'sequel'
require 'logger'
require 'byebug'

require '../lib/ruby_audit.rb'

ENV['DATABASE_NAME'] = 'ruby_audit_' + ENV['APP_ENV']

def db_connection
  db = Sequel.connect(
    adapter: 'postgres',
    host: 'localhost',
    port: '5432',
    database: ENV['DATABASE_NAME'],
    logger: Logger.new(STDOUT)
  )
  db
end
begin
  db_connection.run("CREATE TABLE IF NOT EXISTS sequel_tests (id int, value text)")
end

class SequelTest < Sequel::Model(db_connection[:sequel_tests])
  extend RubyAudit::Audited

  audit :create, :update, :destroy
end

SequelTest.create(id: 1, value: 'value 1')
