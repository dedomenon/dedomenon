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

class CreateLinks < ActiveRecord::Migration
  def self.up
    create_table :links, :force => true do |t|
    t.column :parent_id,   :integer, :references => :instances, :deferrable => true
    t.column :child_id,    :integer, :references => :instances, :deferrable => true
    t.column :relation_id, :integer, :references => :relations, :deferrable => true
  end

  add_index :links, [:child_id], :name => "i_links__child_id"
  add_index :links, [:parent_id], :name => "i_links__parent_id"
  add_index :links, [:parent_id, :child_id, :relation_id], :name => "u_parent_child_relation", :unique => true

  end

  def self.down
    drop_table :links
  end
end
