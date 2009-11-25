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
#     This models relationships between two +Entity+ object. A relation has
#     two participants one parent and one child. The established relationship
#     has two names from both directions; parent to child and child to parent.
#     Also, each end has the cardinality as one or many.
#        * The participants of the relationship are captured by the fields
#     +parent_id+ and +child_id+
#        * The cardinalities at each end are captured by the fields
#        +parent_side_type_id+ and +child_side_type_id+ both of which are 
#        referencing the +RelationSideType+(+relation_side_types+).
#        * The name of each of the relationship is captured by the fields
#        +from_parent_to_child+ and +from_child_to_parent+
#        
# *Fields*
#     Contains following fields:
#       * id
#       * parent_id
#       * child_id
#       * parent_side_type_id
#       * child_side_type_id
#       * from_parent_to_child_name
#       * from_child_to_parent_name
#       
# *Relations*
#     	belongs_to :parent , :class_name => "Entity",  :foreign_key => "parent_id" 
#	belongs_to :child , :class_name => "Entity",  :foreign_key => "child_id" 
#	belongs_to :parent_side_type , :class_name => "RelationSideType",  :foreign_key => "parent_side_type_id" 
#	belongs_to :child_side_type , :class_name => "RelationSideType",  :foreign_key => "child_side_type_id" 
#
class Relation < ActiveRecord::Base
  
	belongs_to :parent , :class_name => "Entity",  :foreign_key => "parent_id" 
	belongs_to :child , :class_name => "Entity",  :foreign_key => "child_id" 
	belongs_to :parent_side_type , :class_name => "RelationSideType",  :foreign_key => "parent_side_type_id" 
	belongs_to :child_side_type , :class_name => "RelationSideType",  :foreign_key => "child_side_type_id" 

  attr_readonly :id,
                :parent_side_type_id,
                :child_side_type_id,
                :parent_id,
                :child_id

  validates_presence_of :from_child_to_parent_name
  validates_presence_of :from_parent_to_child_name
  
  #FIXME: This method is not substituting the ids with urls correctly!
#  def to_json(options = {})
#    
#    json = JSON.parse(super(options))
#    
#    replace_with_url(json, 'id', :Relation, options)
#    replace_with_url(json, 'parent_id', :Entity, options)
#    replace_with_url(json, 'child_id', :Entity, options)
#    replace_with_url(json, 'parent_side_type_id', :RelationSideType, options)
#    replace_with_url(json, 'child_side_type_id', :RelationSideType, options)
#    
#    return json.to_json
#  end
end
