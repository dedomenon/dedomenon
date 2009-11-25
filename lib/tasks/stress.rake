# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 

#RAILS_ENV = ENV['RAILS_ENV'] = 'test'

MAX_ACCOUNTS = 1
MAX_USERS = 1
MAX_DATABASES = 1
MAX_ENTITIES = 1
MAX_DETAILS = 8
MAX_INSTANCES = 2500
MAX_NUMBER_OF_VALUES = 1
MAX_PROPOSITIONS = 5

namespace :dedomenon do

  task :put_stress => :environment do
    create_stress_data
  end
  
end



def create_stress_data
  empty_database
  create_accounts
end

def empty_database
  DetailValueProposition.delete_all
  EntityDetail.delete_all
  Detail.delete_all
  Entity.delete_all
  Database.delete_all
  User.delete_all
  Account.delete_all 
end

def create_accounts
  
  # All accounts are of GOLD type
  account_type = AccountType.find :first, :conditions=> ["name='madb_account_type_gold'"]
  
  #puts "Creating Accounts"
  1.upto MAX_ACCOUNTS do |ac_id|
    account = Account.new(:name => "account#{ac_id}", :country => "Belgium")
    account.end_date = Time.now.next_year
    account.status = 'active'
    account.account_type = account_type
    account.save
    #puts "Creating Users"
    create_users :account => account
    #puts "Creating Databases"
    create_databases :account => account
  end
  
end

def create_users(options={})
  #puts "= Creating users for account #{options[:account].name}"
  1.upto MAX_USERS do |user_id| 
    password = 'stress'
    name = "account#{options[:account].id}_user#{user_id}"
    email = "#{name}@dedomenon.org"
    user = User.new(:login => email,:login_confirmation=> email, 
                    :email =>email, :password => password , 
                    :password_confirmation => password, 
                    :firstname => name)  
    user.user_type_id = 1
    user.verified = 1
    user.account = options[:account]
    user.save!
  end
end

def create_databases(options={})
    #puts "= Creating Databases for account #{options[:account].name}"
  1.upto MAX_DATABASES do |db_id|
    name = "account#{options[:account].id}_database#{db_id}"
    db = Database.new :name => name
    db.account = options[:account]
    db.save
    
    #puts "= Creating Entities"
    create_entities :database => db
  end
  
end

def create_entities(options={})
  #puts "== Creating entities for database #{options[:database].name}"
  1.upto MAX_ENTITIES do |entity_id|
    name = "account#{options[:database].account.id}_database#{options[:database].id}_entity#{entity_id}"
    entity = Entity.new :name => name
    entity.database = options[:database]
    entity.save!
    #puts "= Creating Details"
    create_details :database => options[:database], :entity => entity
    entity.reload
    create_instances :entity => entity
  end
end

def create_details(options={})
  
  1.upto(7) do |detail_id|
    # create the detail
    name = "account#{options[:database].account.id.to_s}_database#{options[:database].id}_entity#{options[:entity].id}_detail#{detail_id}"
    detail = Detail.new :name => name 
    detail.database = options[:database]
    detail.status_id = 1
    detail.data_type_id = detail_id
    detail.save!
    
    # Link it with entity
    e2d = EntityDetail.new
    e2d.entity = options[:entity]
    e2d.detail = detail
    e2d.status_id = 1
    e2d.displayed_in_list_view = true
    e2d.maximum_number_of_values = MAX_NUMBER_OF_VALUES
    e2d.display_order = detail_id    
    e2d.save!
    
    # If its of propsition type, create its propositions
    create_proposition :detail => detail if detail_id == 5
      
    
  end
end

def create_proposition(options={})
  
  1.upto(MAX_PROPOSITIONS) do |prop_id|
    prop = DetailValueProposition.new
    value = "option#{prop_id}"
    prop.detail = options[:detail]
    prop.value = value
    prop.save
  end
end

def create_instances(options={})
  
  1.upto(MAX_INSTANCES) do |instance_id|
    # Create the instance
    instance = Instance.new
    instance.entity = options[:entity]
    instance.save
    
    # Create detail values
    detail_ids = EntityDetail.find :all, :conditions => ["entity_id=?", options[:entity].id]
    detail_ids.collect! { |e2d| e2d.detail_id.to_i }
    
    
    detail_ids.each do |detail_id|
      # Create detail values
      
      detail = Detail.find detail_id
      
      
      value = nil
      datatype = detail.data_type.name
       
      if datatype == 'madb_short_text'
        value = DetailValue.new
        value.value = "value value"
      end
      
      if datatype ==  'madb_long_text'
        value = DetailValue.new
        value.value = "value value"
      end
      
      if datatype == 'madb_date'
        value = DateDetailValue.new
        value.value = Time.now
      end
      
      if datatype == 'madb_integer'
        value = IntegerDetailValue.new
        value.value = 8
      end
      
      if datatype == 'madb_choose_in_list'
        value = DdlDetailValue.new
        prop = DetailValueProposition.find :first, :conditions => ["detail_id=?", detail.id]
        value.value = prop.id
      end
      
      if datatype == 'madb_email'
        value = EmailDetailValue.new
        value.value = 'test@test.com'
      end
      
      if datatype == 'madb_web_url'
        value = WebUrlDetailValue.new
        value.value = 'www.w3c.com'
      end
      
      
      value.detail = detail
      value.instance = instance
      value.save
    end
    
  end
  
end


# Create accounts
  # Create users in them
  # Create databases
    # Create entities
    # Create details

