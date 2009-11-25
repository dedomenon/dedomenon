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
#     Contains detail values for the account_types. Basically an extension 
#     mechinisim.
#     This was introduced to be able to add specifications to accounts without touching the database.
#     If an account_type needs further details, such as the number of databases available to this account type, they would go to this table.
# 
# *Feilds*
# Contains the following fields
# * id
# * account_type_id
# * detail
# * value
# 
# *Relations*
#     belongs_to :account_type
# 
#

class AccountTypeValue < ActiveRecord::Base
  belongs_to :account_type
  
  attr_readonly :id
  
#  def to_json(options = {})
#    return super(options)
#    
##    json = super.to_json(options)
##    base_url = 'http://localhost:3000/'
##    
##    json.gsub!(/("id":\s+\d+)/, '"url": ' + 
##        '"' + base_url + "account_types/#{account_type_id}/account_type_values/#{id}" + '"')
##    
##    json.gsub!(/("account_type_id":\s+\d+)/, '"url": ' + 
##        '"' + base_url + "account_types/#{account_type_id}" + '"')
##    
##    return json
#    
#  end
end
