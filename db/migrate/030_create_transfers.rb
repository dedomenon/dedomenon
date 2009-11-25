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

class CreateTransfers < ActiveRecord::Migration
  def self.up
#FIXME: This migration should be deleted.
#    create_table :transfers, :force => true do |t|
#    t.column :created_at,      :datetime
#    t.column :account_id,      :integer, :references => :accounts, :deferrable => true
#    t.column :user_id,         :integer, :references => :users, :deferrable => true
#    t.column :detail_value_id, :integer, :references => :detail_values, :deferrable => true
#    t.column :instance_id,     :integer, :references => :instances, :deferrable => true
#    t.column :entity_id,       :integer, :references => :entities, :deferrable => true
#    t.column :size,            :integer,  :null => false
#    t.column :file,            :text
#    t.column :direction,       :text
#  end
  end

  def self.down
    #drop_table :transfers
  end
end
