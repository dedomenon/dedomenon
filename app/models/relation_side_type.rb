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
#     Contains the types of relationships an end +Relation+ between two +Entity+ 
#     object might have. The underlying table +relation_side_types+ is
#     referenced by the +relations+ table.
#     Currenly, an end of a +Relation+ only might have one out of two possible
#     values: One, Many.
#     
# *Fields*
#   * id
#   * name
#   
# *Relationships*
#   * has_many :relations
#
class RelationSideType < ActiveRecord::Base

  has_many :relations
  
  attr_readonly :id
  
#  def to_json(options = {})
#    json = JSON.parse(super(options))
#    
#    replace_with_url(json, 'id', :RelationSideType, options)
#    
#    return json.to_json
#  end
end
