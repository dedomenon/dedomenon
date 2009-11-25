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
#   This class relattes two instances by a relation. It should be clear that the 
#   Relation class relates two entities by a relation. Two instances are linked
#   by a link.
#   
# *Attributes*
#   Has following attributes:
#     * id
#     * parent_id
#     * child_id
#     * relation_id
#
#require 'json'
class Link < ActiveRecord::Base
  
  belongs_to :relation
  belongs_to :parent,:foreign_key => "parent_id",  :class_name => "Instance"
  belongs_to :child, :foreign_key => "child_id",:class_name => "Instance"
  
  attr_readonly :id,
                :parent_id,
                :child_id
  
#  def to_json(options = {})
#    json = JSON.parse(super(options))
#    
#    replace_with_url(json, 'id', :Link, options)
#    replace_with_url(json, 'parent_id', :Instance, options)
#    replace_with_url(json, 'child_id', :Instance, options)
#    replace_with_url(json, 'relation_id', :Relation, options)
#    
#    return json.to_json
#  end
  
end
