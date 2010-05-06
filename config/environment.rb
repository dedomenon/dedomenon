################################################################################
#This file is part of Dedomenon.
#
#Dedomenon is free software: you can redistribute it and/or modify
#it under the terms of the GNU Affero General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#Dedomenon is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU Affero General Public License for more details.
#
#You should have received a copy of the GNU Affero General Public License
#along with Dedomenon.  If not, see <http://www.gnu.org/licenses/>.
#
#Copyright 2008 Raphaël Bauduin
################################################################################

# Be sure to restart your webserver when you modify this file.

# Uncomment below to force Rails into production mode
# (Use only when you can't set environment variables through your web/app server)
# ENV['RAILS_ENV'] = 'production'
# ENV['RAILS_ENV'] = 'test'
# Bootstrap the Rails environment, frameworks, and default configuration


require File.join(File.dirname(__FILE__), 'boot')
require File.join(File.dirname(__FILE__), '../vendor/plugins/engines/boot')

require 'yaml'
require 'ostruct'

module Madb
  def self.parse_settings(f)
    config = OpenStruct.new(YAML.load_file(f))
    env_config = config.send(RAILS_ENV)
    config.common.update(env_config) unless env_config.nil?
    return OpenStruct.new(config.common)
  end
end


::AppConfig = Madb::parse_settings("#{RAILS_ROOT}/config/settings.yml")

AppConfig.plugins=[]

Rails::Initializer.run do |config|
  config.gem "daemons"
  config.gem "fastercsv"
    # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use (only works if using vendor/rails).
  # To use Rails without a database, you must remove the Active Record framework
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  #config.load_paths += [ "#{RAILS_ROOT}/vendor/gems/ruby-debug-0.10.0/cli/"]
  #config.load_paths += [ "#{RAILS_ROOT}/vendor/gems/ruby-debug-0.10.0/bin/"]
  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )
  #config.load_paths += Dir["#{RAILS_ROOT}/vendor/gems/**"].map do |dir| 
#    File.directory?(lib = "#{dir}/lib") ? lib : dir
#  end
  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_madb_session',
    :secret      => 'a6eda86d70edfa5b6c3f9cdc9e5fb0edd5ee39b98ac8db189238e5faa0a331cadc39b8d8fb3e046984cfa0b9a582c320b5ecf033950d9ee6c331ad3745acd454'
  }


  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with 'rake db:sessions:create')
  config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  #
  config.action_controller.use_accept_header = false
end

# Add new inflection rules using the following format 
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Include your application configuration below
require 'json'
CONFIG = YAML::load(File.open("#{RAILS_ROOT}/config/environments/app-config-#{RAILS_ENV}.yml"))

#require 'nano/kernel/require_nano'
#require_nano 'string/::random'

class String
  def self.random(len=8)
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    s = ""
    1.upto(len) { |i| s << chars[rand(chars.size-1)] }
    return s
  end
end


require 'translations'
class ActionMailer::Base
	include Translations
  helper_method :t
end

class MadbSettings
  def self.european_countries
    ["Austria", "Belgium", "Cyprus", "Czech Republic", "Denmark", "England", "Espana", "Estonia", "Finland", "France", "Germany", "Greece", "Hungary", "Ireland", "Italy", "Latvia", "Lithuania", "Luxembourg", "Malta", "Poland", "Portugal", "Slovakia", "Slovenia", "Spain", "Sweden", "Netherlands", "United Kingdom"]
  end
end


class TranslationsConfig
    @@scopes = [] # [ { :scope_name => "database", :id_filter => proc_returning_current_db_id }, {:scope_name => "account", :id_filter => proc_returning_account_id}, {:scope_name => "system", :id_filter => nil} ]
    @@scopes = [ {:scope_name => "system", :id_filter => nil} ]
    @@scopes = [ {:scope_name => "system", :id_filter => nil} ,
                 {:scope_name => "account", :id_filter => :get_account_id}, 
                 {:scope_name => "database", :id_filter => :get_database_id}, 
    ]

    def self.scopes
      @@scopes
    end


    def self.cookie_name
      :user_language
    end
end

#ActionView::Base.erb_trim_mode = '<>'
#
module ActionView
  module Helpers
    module FormTagHelper
      alias :old_submit_tag :submit_tag
      def submit_tag(value = "Save changes", options = {})
        old_submit_tag(value, options.update( :class => "submit"))
      end
    end
  end
end

#alias :old_submit_tag :submit_tag
#def submit_tag(value = "Save changes", options = {})
#  old_submit_tag(value, options.update( :class => "submit"))
#end
#ActionController::Base.allow_concurrency


ActiveRecord::Base.colorize_logging = false
#require 'paypal'

module MadbClassFromName
  def class_from_name(className)
    const = ::Object
    klass = const.const_get(className)
    if klass.is_a?(::Class)
      klass
    else
      raise "Class #{className} not found"
    end
  end
end

# Add it globally!
include MadbClassFromName

# Add the MadbClassFromName to Active Record
module ActiveRecord
  class Base
    include MadbClassFromName
  end
end


# Add the MadbClassFromName to Action Conroller
module ActionController
  class Base
    include MadbClassFromName
  end
end

# Add the MadbClassFromName to Action View
module ActionView
  class Base
    include MadbClassFromName
  end
end

# Add the MadbClassFromName to the Testing framework
module Test
  module Unit
    class TestCase
      include MadbClassFromName
    end
  end
end


I18n.load_path << Dir[ File.join(RAILS_ROOT, 'config', 'locales', 'rails', '*.{rb,yml}') ] 


