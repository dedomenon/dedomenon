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

# *Description*
#     Represents a database in the system. A database is associated with an
#     account and has a name. The tabels of the datbase are stored in the
#     entities table
# *Fields*
# Has following fields
#   * id
#   * account_id
#   * name
#
# *Relations*
#   belongs_to :account
#   has_many :entities
#   has_many :details
#
class Database < ActiveRecord::Base
  
  belongs_to :account
  has_many :entities
  has_many :details       
  
  attr_readonly   :id,
                  :account_id
                
  attr_protected  :entities_url,
                  :details_url

  # *Description*
  #     This code block checks if any database account has reached
  # the limit of maximum allowed number of databases.
  # *Workflow*
  #     current number of databases and maximum allowed number of databases
  # are checked.
  
  validates_presence_of :name
  
  # Fix made so that user can rename the databases even on reaaching the limit.
  validates_each :name, :on => :create do |record, attr|
    current_database_number = record.account.databases.count.to_i
    limit_database_number = record.account.account_type.number_of_databases.to_i
    if current_database_number >= limit_database_number
      record.errors.add attr, 'madb_limit_of_account_reached'
    end
  end
  
end
