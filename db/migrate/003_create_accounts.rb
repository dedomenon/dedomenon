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

class CreateAccounts < ActiveRecord::Migration
  def self.up
    
    # Some columns are moved becacuse they are not going to the 
    # open source version
    create_table :accounts, :force => true do |t|
    t.column :account_type_id,      :integer #, :references => :account_types, :deferrable => true
    t.column :name,                 :text,                            :null => false
    t.column :street,               :text
    t.column :zip_code,             :text
    t.column :city,                 :text
    t.column :country,              :text
    # Status and end date should not be in the standard versionn, but 
    # yet our authenticaiton system is dependent on that and they would be needed
    # in a fresh install.
    # status field is used by Account#expired?
    # end_date field is used by Account#allows_login? 
    t.column :status,               :text,    :default => "inactive"
    t.column :end_date,             :date
#    t.column :subscription_id,      :text #,    :references => nil
#    t.column :subscription_gateway, :text
#    
    # used by Account#vat we will decide its futrue afterwards.
    t.column :vat_number,           :text
#    t.column :attachment_count,     :integer, :default => 0
    end
  end

  def self.down
    drop_table :accounts
  end
end
