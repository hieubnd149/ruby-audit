# Loading the app
root_path = File.expand_path('../../', __FILE__)
$LOAD_PATH.unshift(root_path) unless $LOAD_PATH.include?(root_path)

ENV['APP_ENV'] = 'test'

require 'sequel'
require 'logger'
require 'byebug'

require './lib/ruby_audit'

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

Sequel.extension :migration
begin
  db_connection.run("DROP DATABASE IF EXISTS #{ENV['DATABASE_NAME']}")
  db_connection.run("CREATE DATABASE #{ENV['DATABASE_NAME']}")
rescue => e
  puts 'Could not setup database automatically. Please setup by yourself'
end

# Prepare database for testing
begin
  db_connection.run(
    'CREATE TABLE IF NOT EXISTS sequel_tests (id int, value text)'
  )
  db_connection.run(
    <<~SQL
      CREATE OR REPLACE FUNCTION TG_SEQUEL_TEST()
        RETURNS trigger AS
      $BODY$
        BEGIN
           RAISE INFO 'transaction_id=%', txid_current();
           RETURN NEW;
        END;
      $BODY$ LANGUAGE plpgsql;
    SQL
  )
  db_connection.run('DROP TRIGGER IF EXISTS TG_SEQUEL_TEST ON sequel_tests')
  db_connection.run(
    <<~SQL
      CREATE TRIGGER TG_SEQUEL_TEST
      AFTER INSERT OR UPDATE OR DELETE
      ON SEQUEL_TESTS
      FOR EACH STATEMENT
      EXECUTE PROCEDURE TG_SEQUEL_TEST();
    SQL
  )
end

module Helpers
  class SequelTest < Sequel::Model(db_connection[:sequel_tests])
    extend RubyAudit::Audited

    audit :create, :update, :destroy
  end

  def create_record
    SequelTest.create(id: 1, value: 'value 1')
  end

  def update_record
    record = SequelTest.find(id: 1)
    record&.update(value: 'value 1 updated')
  end

  def destroy_record
    record = SequelTest.find(id: 1)
    record&.destroy
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.include Helpers

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def kill_spawn_processes(keyword)
  pids =
    `ps aux | grep '#{keyword}' | awk '{print $2}'`
      .split
      .map(&:to_i)
      .reject { |pid| pid == Process.pid }
  pids.each do |pid|
    begin
      Process.kill('TERM', pid)
      Process.waitpid(pid)
    rescue
      puts "Could not kill process"
    end
  end
end
