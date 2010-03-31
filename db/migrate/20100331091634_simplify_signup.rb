class SimplifySignup < ActiveRecord::Migration
  def self.up
    query = "ALTER TABLE accounts alter column name drop not null"
    ActiveRecord::Base.connection.execute(query)
  end

  def self.down
    query = "ALTER TABLE accounts alter column name set not null"
    ActiveRecord::Base.connection.execute(query)
  end
end
