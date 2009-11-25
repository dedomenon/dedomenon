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
require 'json'
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
  
  #FIXME: Add the options behaviour as a standard behaviour
  #FIXME: When the initial string is null, should proceed next.
#  def to_json(options={})
#    
#    json = JSON.parse(super(options))
#    
#    replace_with_url(json, 'id', :Database, options)
#    replace_with_url(json, 'account_id', :Account, options)
#    
#    format = ''
#    format = '.' + options[:format] if options[:format]
#    
#    json[:entities_url] = @@lookup[:Database] % [@@base_url, self.id]
#    json[:entities_url] += (@@lookup[:Entity] % ['', '']).chop + format
#    
#    json[:details_url] = @@lookup[:Database] % [@@base_url, self.id]
#    json[:details_url] += (@@lookup[:Detail] % ['', '']).chop + format
#    
#    return json.to_json
#    
#    #json = old_to_json(opts)
#    
##    # remove any whitespace
##    json.strip!
##    
##    # Subtitute the escape sequence chracters
##    json.gsub!(/\\/, '')
##    
##    # Delete the bracket
##    json.delete!('}')
##    
##    # remove the enclosing quote symbols
##    if json.length > 2
##      json = json[1, json.length]
##    end
##    
##    json.chop!
##    
##    
##    base_url = 'http://localhost:3000/'
##    str = '"details": '          + '"' + base_url + "databases/#{id}/details.json"   + '"' + ', ' +
##          '"entities": '       + '"' + base_url + "databases/#{id}/entities.json" + '"' 
##        
##          
##          
##    
##    
##    
##    json = json + ', ' + str + '}'
##    
##    # Subtitute the account URL
##    account_url = base_url + "accounts/#{account_id}"
##    json.gsub!(/("account_id":)\s+\d+/, "\"account_url\": \"#{account_url}\"")
##    json.gsub!(/("id":)\s+\d+/, '"url": ' + base_url + "databases/#{id}")
##    
##    
##    return json;
#    
#       
#  end
end
