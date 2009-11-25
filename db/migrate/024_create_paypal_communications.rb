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

class CreatePaypalCommunications < ActiveRecord::Migration
  def self.up
#FIXME: This migration should be deleted.
#    create_table :paypal_communications, :force => true do |t|
#    t.column :t,                  :datetime
#    t.column :account_id,         :integer, :references => :accounts, :deferrable => true
#    t.column :txn_type,           :text
#    t.column :communication_type, :text
#    t.column :direction,          :text
#    t.column :content,            :text
#  end
  end

  def self.down
    #drop_table :paypal_communications
  end
end
