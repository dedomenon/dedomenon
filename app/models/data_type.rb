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
#     Represents a datatype in the system.
#     The datatype has a name which is a translateable token. Further more,
#     it has another field call class_name. This is the name of the class
#     that will handle this datatype in Ruby. The class reffered to here will
#     have the capability to display the value in the lists and public forms.
#   
#   *Available_Types*
#     Currently available types are:
#     id |     name            |    class_name
#     ---------------------------------------------
#     1  | madb_short_text     |  SimpleDetailValue
#     2  | madb_long_text      |  LongTextDetailValue
#     3  | madb_date           |  DateDetailValue
#     4  | madb_integer        |  IntegerDetailValue
#     5  | madb_choose_in_list |  DdlDetailValue
#     6  | madb_email          |  EmailDetailValue
#     7  | madb_web_url        |  WebUrlDetailValue
#     8  | madb_s3_attachment  |  S3Attachment

# *Feilds*
# Has following fields:
#   * id
#   * name
#   * class_name
#   
# *Relations*
#   has_many :details
class DataType < ActiveRecord::Base
  
  has_many :details
  
  attr_readonly :id
  
#  def to_json(options = {})
#    
#    json = JSON.parse(super(options))
#    
#    replace_with_url(json, 'id', :DataType, options)
#    
#    return json.to_json
#  end
end
