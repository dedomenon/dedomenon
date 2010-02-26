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
#     A details is a defination of a field of an +Entity+. Similar to the tables
#     concept in the RDBMS world. Each +Detail+ has an id, a name and a
#     +Datatype+ (+data_type_id+) and is associated with a +Database+ (wtih
#     +database_id+) column.
#     
# *Fields*
# Contains following fields:
#   * id
#   * name
#   * data_type_id
#   * status_id
#   * database_id
#
# *Relationships*
#   * has_many :detail_value_propositions
#   * has_many :entity_details
#   * has_and_belongs_to_many :entities, :join_table => "entities2details"
#   * belongs_to :data_type
#   * belongs_to :detail_status
#   * belongs_to :database

require 'json'
class Detail < ActiveRecord::Base
  
  has_many :detail_value_propositions
  has_many :entity_details
  has_and_belongs_to_many :entities, :join_table => "entities2details"
  belongs_to :data_type
  belongs_to :detail_status
  belongs_to :database
  
  
  
  #FIXME: Should all be readonly except the name?
  attr_readonly :id,
                :data_type_id,
                :database_id
  
  validates_presence_of :name,
                        :data_type_id,
                        :database_id
                      
  validates_each :name do |record,attr,value|
      if value.downcase=="id"
        record.errors.add attr, 'madb_detail_name_cannot_be_id'
      end
      if value.nil? or value==""
        record.errors.add attr, 'madb_detail_name_cannot_be_empty'
      end
  end

  validates_uniqueness_of :name, :scope => "database_id", :message => "madb_duplicate_detail_name_in_db"

  # returns the Class handling this detail's value. The class is determined with the detail's data_type's class_name attribute. 
  # class_from_name is defined in the module MadbClassFromName in config/environment.rb
  def value_class
    class_from_name(data_type.class_name)
  end

  def yui_column(h={})
# datasource utf-8 fix
    "{ field:  \"['#{name}']\" , label:  '#{name}', key: '#{sanitized_name}', formatter: #{value_class.yui_formatter(h)}, sortable: #{value_class.yui_sortable(h)} }"
  end

  def yui_field(h={})
# datasource utf-8 fix
    "{ key: \"['#{name}']\" , parser: #{value_class.yui_parser(h)} }"
  end

  def sanitized_name
    #ActiveSupport::JSON::Encoding.escape(name).gsub(/"/, "").gsub(/\\/,"")
    s = name.downcase.gsub(/[^a-z0-9 _]/, "").gsub(/ /,"_")
    if s==""
      s=ActiveSupport::JSON::Encoding.escape(name).gsub(/"/, "").gsub(/\\/,"")
    end
    return s
  end
  
end
