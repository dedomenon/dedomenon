class AddCreatedAtAndLastLoginToAccount < ActiveRecord::Migration
  def self.up
    add_column :accounts, :created_at, :timestamp
    add_column :accounts, :last_login_at, :timestamp
  end

  def self.down
    remove_column :accounts, :last_login_at
    remove_column :accounts, :created_at
  end
end
