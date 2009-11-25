class AddTimestamping < ActiveRecord::Migration
  def self.up
    # for instances
    add_column :instances, :updated_at, :timestamp
    
    # for detail values
    add_column :detail_values, :created_at, :timestamp
    add_column :detail_values, :updated_at, :timestamp
    
    #for date detail values
    add_column :date_detail_values, :created_at, :timestamp
    add_column :date_detail_values, :updated_at, :timestamp
    
    # for integer detail values
    add_column :integer_detail_values, :created_at, :timestamp
    add_column :integer_detail_values, :updated_at, :timestamp
    
    # for ddl detail values
    add_column :ddl_detail_values, :created_at, :timestamp
    add_column :ddl_detail_values, :updated_at, :timestamp
    
    
    
    
  end

  def self.down
    # for instances
    remove_column :instances, :updated_at
    
    # for detail values
    remove_column :detail_values, :created_at
    remove_column :detail_values, :updated_at
    
    #for date detail values
    remove_column :date_detail_values, :created_at
    remove_column :date_detail_values, :updated_at
    
    # for integer detail values
    remove_column :integer_detail_values, :created_at
    remove_column :integer_detail_values, :updated_at
    
    # for ddl detail values
    remove_column :ddl_detail_values, :created_at
    remove_column :ddl_detail_values, :updated_at
  end
end
