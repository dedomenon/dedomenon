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

# Contains following tasks. 
#  create_users
#  create_databases
#  create_crosstab
#  load_translations
#  copy_config_file
#  setup
# FUTURE: Task should be able to obtain the passwords of the users and then
#         generated the config/database.yml file automatically and after it,
#         it should automatically run migrations.

require 'rubygems'
require 'yaml'



user_info_header = %Q~
-------------------------------------------------------------
|                       Step 1                              |
|               Dedomenon User's Creation                   |
-------------------------------------------------------------
| This step will create two users in your PostgesSQL server.|
|                                                           |
|   * 'myowndb' user is normal user used for production     |
|     and development databases.                            |
|   * 'myowndbtester' is a super user for test database     |
|                                                           |
| You'll be asked for the passwords of these users.         |
| Remember them for later references                        |
|                                                           |
-------------------------------------------------------------
~

database_info_header = %Q~
-------------------------------------------------------------
|                       Step 2                              |
|               Dedomenon Databases Creation                |
-------------------------------------------------------------
| This step will create three databases:                    |
|                                                           |
|   * 'myowndb_dev' is development database with owner      |
|     'myowndb'                                             |
|   * 'myowndb_test' is the test database with owner        |
|     'myowndbtester'                                       |
|   * 'myowndb_prod'is production databae with owner        |
|     'myowndb'                                             |
|                                                           |
-------------------------------------------------------------
~
crosstab_info_header = %Q~
-------------------------------------------------------------
|                       Step 3                              |
|               Crosstab Function Creation                  |
-------------------------------------------------------------
|                                                           |
|  This step will create crosstab functions in databases.   |
|                                                           |
------------------------------------------------------------|
~

#loading_translations = %Q~
#-------------------------------------------------------------
#|                        Step 4                             |
#|               Loading Database Translations               |
#-------------------------------------------------------------
#|                                                           |
#|  This step will load UI translations to database          |
#|  This will ask you for the password of                    |
#|  PostgreSQL user 'myowndb'                                |
#|                                                           |
#------------------------------------------------------------|
#~

migrations_header = %Q~
-------------------------------------------------------------
|                        Step 4                             |
|                   Running Migrations                      |
-------------------------------------------------------------
|                                                           |
|  This step will build schema of your production database  |
|                                                           |
------------------------------------------------------------|
~

demo_account_header = %Q~
-------------------------------------------------------------
|                        Step 5                             |
|                  Create Demo Account                      |
-------------------------------------------------------------
|                                                           |
|  This step will create demo account for you so that you   |
|  can use the application. You'll be asked for your name,  |
|  login and password to create a user for you.             |
|                                                           |
------------------------------------------------------------|
~

# This hash will hold the passwords of the database users which are
# prompted by create_user task
user_passwords = {}

namespace :dedomenon do

  #FIXME: Should properly report what its doing
  desc 'Creates users for dedomenon in postgres'
  task :create_users do 
    puts user_info_header
    [
      # First is the user name, rest are the options
      ['myowndb', '--no-superuser', '--no-createdb', '--no-createrole'],
      ['myowndbtester', '--superuser']
    ].each do |db_user| 
      options = "#{db_user.join(' ')}"
      puts "Creating user '#{db_user[0]}'..."
      command = "sudo -u postgres createuser #{options} 1>/dev/null"
      user_passwords[db_user[0]] = get_confirmed_input("Enter password for postgres user '#{db_user[0]}'", true)
      # Create the user and then alter the password
      system command
      alter_role_query = "ALTER ROLE #{db_user[0]} WITH ENCRYPTED PASSWORD '#{user_passwords[db_user[0]]}'"
      system %Q[ sudo -u postgres psql -c "#{alter_role_query};" 1>/dev/null]
      puts "User '#{db_user[0]}' created..."
    end
  end
  
  #FIXME: Should properly report what its doing
  desc 'Creates databases for dedomenon'
  task :create_databases => :create_users do
    puts database_info_header
    [
      # First is the database name, second is the owner of database
      ['myowndb_dev', 'myowndb'],
      ['myowndb_test', 'myowndbtester'],
      ['myowndb_prod', 'myowndb']
      #['myowndb_ui_translations', 'myowndb'],
    ].each do |database|
      puts "Creating database '#{database[0]}' for user '#{database[1]}'..."
      options = " #{database[0]} -O #{database[1]}"
      command = "sudo -u postgres createdb #{options} -E UNICODE 1>/dev/null"
      system command
      # Now alter the ownership of the public schema otherwise
      # Loading of the translations dump will give a single error.
      alter_schema_public = "ALTER SCHEMA public OWNER TO #{database[1]};"
      system %Q{sudo -u postgres psql #{database[0]} -c "#{alter_schema_public}" 1>/dev/null}
      puts "Database '#{database[0]}' created with owner '#{database[1]}'"
      #puts command
    end
  end
  
  desc 'Creates cross_tab functions in dedomenon databases'
  task :create_crosstab => :create_databases do
    puts crosstab_info_header
    [
      'myowndb_dev',
      'myowndb_test',
      'myowndb_prod',
    ].each do |database|
      puts "Creating cross_tab fucntions for database '#{database}'..."
      sql_script = "#{RAILS_ROOT}/db/create_crosstab.sql"
      command = "sudo -u postgres psql -d #{database} < #{sql_script} 1>/dev/null"
      system command
      puts "cross_tab functions created for database '#{database}'"
      #puts command
    end
  end
  
#  desc 'Loads the translations database for dedomenon UI'
#  task :load_translations => :create_databases do
#    puts loading_translations
#    sql_script = "#{RAILS_ROOT}/db/myowndb_ui_translations_dump.sql"
#    puts "Loading UI translations to myowndb_ui_translations database..."
#    puts "This will ask you for the password of the 'myowndb' user."
#    command = "psql myowndb_ui_translations -h localhost -U myowndb -W < #{sql_script} 1>/dev/null"
#    system command
#    puts "Translations database loaded"
#    #puts command
#  end
  
  desc 'Generates config/database.yml'
  task :generate_config_file  do
    puts "Generating config/database.yml..."
    yml = plug_passwords("#{RAILS_ROOT}/config/database.yml.example", user_passwords)
    File.open("#{RAILS_ROOT}/config/database.yml", "w") do |file|
      file.puts "# Autogenerated database connection info on #{Time.now.to_s}"
      file.puts "# By rake task dedomenon:setup"
      file.puts(yml.to_yaml)
    end
    puts "Generation of config/database.yml is complete"
  end
  
  desc 'Runs migrations on production database'
  task :run_migrations => :generate_config_file do
    puts migrations_header
    RAILS_ENV = ENV['RAILS_ENV'] = 'production'
    Rake::Task['db:migrate'].invoke
  end
  
  desc 'Setups dedomenon for you including users, databases.'
  task :setup => [:create_crosstab, :run_migrations] do
    puts demo_account_header              
    RAILS_ENV = ENV['RAILS_ENV'] = 'production'
    login_info = create_account_and_users
                  
    puts "* Now you can run applciation by ruby script/server -e production"
    puts "* If you want to use application in test and development modes," 
    puts "  You will have to run migratiosn yourself by:"
    puts "   * RAILS_ENV=development rake db:migrate"      
    puts "   * RAILS_ENV=test rake db:migrate"      
    puts ""
    puts " * Demo account is available for you:"
    puts "    * #{login_info[0]} is admin user"
    puts "    * Password is the one you entered"
    
  end
  
  #FIXME: Thik about this task. It has following problems:
  # * You have to run dedomenon:setup before this 
  # * If we make dedomenon:setup as its dependency, then running it alone
  #   will only succeed if the dedomenon:setup is not run yet. We let it go
  #   for now and will improve other tasks to check their actions before
  #   they do anything.
  #   Raph: Let me know your ideas on this. (Mohsin)
  #
  desc 'Setups the development environemnt for you.'
  task :setup_development do
    RAILS_ENV = ENV['RAILS_ENV'] = 'development'
    Rake::Task['db:migrate'].invoke
    
    login_info = create_account_and_users
    
    puts " * Test account is available for you:"
    puts "    * #{login_info[0]} is admin user"
    puts "    * Password is the one you entered"
  end
  
  desc 'Drops all the postgres databases and postgres users'
  task :purge do
    # Drop the databases
    ['myowndb_dev',
      'myowndb_test',
      'myowndb_prod'
    ].each do |database|
      puts "Dropping database '#{database}'..."
      system %Q~ sudo -u postgres psql -c "DROP DATABASE #{database};" 1>/dev/null~
      puts "Database '#{database}' dropped..."
    end
    
    # Drop the users
    [
      'myowndbtester',
      'myowndb'
    ].each do |user|
      puts "Dropping user '#{user}'..."
      system %Q~ sudo -u postgres psql -c "DROP ROLE #{user};" 1>/dev/null~
      puts "User '#{user}' dropped..."
    end
  end
  # Disables echo of stdin, and returns the original settings
  def disable_echo
    old_settings = getattr($stdin)
    new_settings  = old_settings.dup
    new_settings.c_lflag &= ~ECHO
    setattr($stdin, TCSANOW, new_settings)
    return old_settings 
  end

  # Restores echo settings with the original settings returned by disable_echo
  def restore_echo(settings)
    setattr($stdin, TCSANOW, settings)
  end

  # 
  # Gets input from user twice to make sure its correct.
  # First argument is prompt to display and second is whether
  # echo should be displayed or not.
def get_confirmed_input(prompt, no_echo = false, min_len = 1, max_len = 0)
  
  # for not showing the passwords entered by users
  require 'termios'
  include Termios

  first = ''
  second = nil
  
  # Until the two match
  while first != second do
    # isable echo if provided
    s = disable_echo if no_echo
    # Get for the first time
    print "#{prompt}: "
    first = $stdin.gets.chomp
    
    # reject if shorter
    if first.length < min_len
      puts "\nInput length must be at least #{min_len} characters"
      restore_echo(s) if no_echo
      next
    end
    
    # reject if longer
    if max_len > 0 and first.length > max_len
      puts "\nInput length should be less then #{max_len} characters"
      restore_echo(s) if no_echo
      next
    end
    
    # Get for the second time
    print "\nEnter it again: "
    second = $stdin.gets.chomp
    
    # Restore the echo if provided
    restore_echo(s) if no_echo

    $stderr.puts 'Items do not match!' if first != second
  end
  
  return first
end

def get_input(prompt)
  $stdout.print "#{prompt}: "
  return $stdin.gets.chomp
end

# This function plugins the passwords of each user in appropiate section
# First argumetn is string having full path of file to be altered
# Second is a hash where passwords are hashed by user names
def plug_passwords(yml_file, passwords)
  
  yml = YAML.load_file yml_file
  
  # For the connection information of each of the database
  yml.each do |database, connection_info|
    # For each of the password 
    passwords.each do |username, password|
      # If its this user, place password
      if connection_info['username'] == username
        connection_info['password'] = password
      end
    end
  end
  return yml
end


# Creates a demo account and users
def create_account_and_users
  # Create two users for the demo account so that user can log in.
  # First user is super user with id 777 , the ohter is ordinary with 999.

  first_name = get_input("Please enter your first name")
  last_name = get_input("Please enter your last name")
  admin_login = get_input('Please enter your email address (john@gmail.com for example)')
  password = get_confirmed_input("Please enter password for your account", true, 5, 40)
  account_name = "#{first_name} #{last_name} Account"
  
  # Create a demo account so that user can log in after installation
  # This can be removed later on by the user.
  # ID of this account is intentionally to be 111
  Account.create(
    :account_type_id                              => 1,
    :name                                         => account_name,
    :street                                       => 'TCP/IP highway',
    :zip_code                                     => '80',
    :city                                         => 'HTTP',
    :country                                      => 'Internet',
    :status                                       => 'active',
    :end_date                                     => nil,
    :vat_number                                   => 'N/A'
      
  )
  
  puts " "
  puts "* Account created titiled '#{account_name}'..."
  # Change its id
  #account_name = ActiveRecord::Base.connection.quote_string(account_name)
  #ActiveRecord::Base.connection.execute("UPDATE accounts SET id=111 WHERE name='#{account_name}';")
   
  user = User.new(
    :id                                             =>  777,
    :account_id                                     => 1,
    :user_type_id                                   => 1,
    :login                                          => admin_login,
    :password                                       => password,
    :email                                          => admin_login,
    :firstname                                      => first_name,
    :lastname                                       => last_name,
    :verified                                       => 1
  )
    
  user.login_confirmation = user.login
  user.password_confirmation = user.password
  user.save!
    
  puts "* User created with login '#{admin_login}'..." 
  puts " "
  puts " "
  
  return [admin_login, password]
    
    
  
    
end

  
end

