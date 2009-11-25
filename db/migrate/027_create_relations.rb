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

class CreateRelations < ActiveRecord::Migration
  def self.up
    create_table :relations, :force => true do |t|
    t.column :parent_id,                 :integer, :null => false, :references => :entities, :deferrable => true
    t.column :child_id,                  :integer, :null => false, :references => :entities, :deferrable => true
    t.column :parent_side_type_id,       :integer, :null => false, :references => :relation_side_types, :deferrable => true
    t.column :child_side_type_id,        :integer, :null => false, :references => :relation_side_types, :deferrable => true
    t.column :from_parent_to_child_name, :text,    :null => false
    t.column :from_child_to_parent_name, :text
  end

  add_index :relations, [:child_id], :name => "i_relations__child_id"
  add_index :relations, [:parent_id], :name => "i_relations__parent_id"

  end

  def self.down
    drop_table :relations
  end
end
