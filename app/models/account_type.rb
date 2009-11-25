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
#     Encapsulates possible types of accounts in myowndb
# Contains following fields:
# * id
# * name
# * active
# * free
# * number_of_users
# * number_of_databases
# * monthly_fee
# * maximum_file-size
# * maxium_monthly_file_transfer
# * maximum_attachment_number
# 
# *Fields*
#   has_many :account_type_values
#   has_many :accounts
#
class AccountType < ActiveRecord::Base
  
  
  has_many :account_type_values
  has_many :accounts
  
  attr_readonly :id
  
end
