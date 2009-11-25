class AddApiKeyToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :api_key, :text
  end

  def self.down
    remove_column :users, :api_key
  end
end
