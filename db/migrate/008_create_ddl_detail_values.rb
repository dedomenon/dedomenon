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

class CreateDdlDetailValues < ActiveRecord::Migration
  def self.up
    create_table :ddl_detail_values, :force => true do |t|
    t.column :detail_id,                   :integer, :references => :details, :deferrable => true
    t.column :instance_id,                 :integer, :references => :instances, :deferrable => true
    t.column :detail_value_proposition_id, :integer, :references => :detail_value_propositions, :deferrable => true
  end

  add_index :ddl_detail_values, [:detail_id], :name => "i_ddl_detail_value__detail_id"
  add_index :ddl_detail_values, [:instance_id], :name => "i_ddl_detail_value__instance_id"

  end

  def self.down
    drop_table :ddl_detail_values
  end
end
