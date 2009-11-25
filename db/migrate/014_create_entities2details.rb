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

class CreateEntities2details < ActiveRecord::Migration
  def self.up
    create_table :entities2details, :force => true do |t|
    t.column :entity_id,                :integer, :references => :entities, :deferrable => true
    t.column :detail_id,                :integer, :references => :details, :deferrable => true
    t.column :status_id,                :integer, :references => :detail_status, :deferrable => true
    t.column :displayed_in_list_view,   :boolean, :default => true
    t.column :maximum_number_of_values, :integer, :default => 1, :null => false
    t.column :display_order,            :integer, :default => 100
  end

  add_index :entities2details, [:detail_id], :name => "entities2details__detail_id"
  add_index :entities2details, [:entity_id], :name => "entities2details__entity_id"
  add_index :entities2details, [:detail_id], :name => "i_entities2details__detail_id"
  add_index :entities2details, [:entity_id], :name => "i_entities2details__entity_id"

  end

  def self.down
    drop_table :entities2details
  end
end
