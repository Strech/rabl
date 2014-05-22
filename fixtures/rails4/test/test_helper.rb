# Load Silence Functionality
require File.expand_path(File.dirname(__FILE__) + "/../../../test/silence.rb")

# Load Environment
silence_warnings do
  ENV["RAILS_ENV"] = "test"
  require File.expand_path('../../config/environment', __FILE__)
  require 'rails/test_help'
end

# Load Riot Test Environment
require File.expand_path(File.dirname(__FILE__) + "/../../../test/integration/test_init.rb")

# Run Migrations
silence_stream(STDOUT) do
  dbconf = YAML::load(File.open('config/database.yml'))[Rails.env]
  ActiveRecord::Base.establish_connection(dbconf)
  ActiveRecord::Base.logger = Logger.new(File.open('log/database.log', 'a'))
  silence_stream(STDOUT) { ActiveRecord::Migrator.up('db/migrate') }
end

class Riot::Situation
  def app
    Rails.application
  end
end

unless Rails::VERSION::MAJOR >= 4 && Rails::VERSION::MINOR >= 1 && Rails::VERSION::TINY >= 1
  class ActiveSupport::TimeWithZone
    def as_json(options = nil)
      if ActiveSupport::JSON::Encoding.use_standard_json_time_format
        # wait for Rails 4.1.1
        # https://github.com/rails/rails/commit/c0965004486f2ea5a9656ba718a3377c9614f97d
        xmlschema
      else
        %(#{time.strftime("%Y/%m/%d %H:%M:%S")} #{formatted_offset(false)})
      end
    end
  end
end

