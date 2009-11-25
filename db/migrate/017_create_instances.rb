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

class CreateInstances < ActiveRecord::Migration
  def self.up
    create_table :instances, :force => true do |t|
    t.column :entity_id,  :integer, :references => :entities, :deferrable => true
    t.column :created_at, :datetime
  end

  add_index :instances, [:entity_id], :name => :i_instances__entity_id

  end

  def self.down
    drop_table :instances
  end
end
