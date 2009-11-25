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

class OptimisticLockingSupport < ActiveRecord::Migration
  def self.up
    
    # Accounts and users
     add_column :accounts,                   :lock_version, :integer, :default => 0
     # Optimistic locking for users is disabled for now because the 
     # session containsa whole user object which tends to fail the authentication
     # controller tests due to optimistic locking
     #add_column :users,                      :lock_version, :integer, :default => 0
    
    # Databases, Entities and Relations
    add_column :databases,                  :lock_version, :integer, :default => 0
    add_column :entities,                   :lock_version, :integer, :default => 0
    add_column :relations,                  :lock_version, :integer, :default => 0
    
    # Instances, Details and detail values
    add_column :instances,                  :lock_version, :integer, :default => 0
    add_column :details,                    :lock_version, :integer, :default => 0
    add_column :detail_values,              :lock_version, :integer, :default => 0
    add_column :integer_detail_values,      :lock_version, :integer, :default => 0
    add_column :date_detail_values,         :lock_version, :integer, :default => 0
    add_column :ddl_detail_values,          :lock_version, :integer, :default => 0
    add_column :detail_value_propositions,  :lock_version, :integer, :default => 0
    
    # Accounts and Users
    Account.update_all('lock_version = 0')
    #User.update_all('lock_version = 0')
    
    # Databases, Entities and Relations
    Database.update_all('lock_version = 0')
    Entity.update_all('lock_version = 0')
    Relation.update_all('lock_version = 0')
    
    # Instances, Details and detail values
    Instance.update_all('lock_version = 0')
    Detail.update_all('lock_version = 0')
    DetailValue.update_all('lock_version = 0')
    IntegerDetailValue.update_all('lock_version = 0')
    DateDetailValue.update_all('lock_version = 0')
    DdlDetailValue.update_all('lock_version = 0')
    DetailValueProposition.update_all('lock_version = 0')
  end

  def self.down
     
    # Accounts and users
    remove_column :accounts,                    :lock_version
    # Optimistic locking for users is disabled for now because the 
    # session containsa whole user object which tends to fail the authentication
    # controller tests due to optimistic locking
    #remove_column :users,                       :lock_version
    
    # Databases, Entities and Relations
    remove_column :databases,                   :lock_version
    remove_column :entities,                    :lock_version
    remove_column :relations,                   :lock_version
    
    # Instances, Details and detail values
    remove_column:instances,                    :lock_version
    remove_column :details,                     :lock_version
    remove_column :detail_values,               :lock_version
    remove_column :integer_detail_values,       :lock_version
    remove_column :date_detail_values,          :lock_version
    remove_column :ddl_detail_values,           :lock_version
    remove_column :detail_value_propositions,   :lock_version
  end
end
