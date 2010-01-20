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

require "erb"
require 'entities2detail.rb'

include ERB::Util
# *Description*
#   All the values entered in the MyOwnDB tables are stored in three tables
#   based on the type of the value:
#      * The text values are stored in +DetailValue+(+detail_values+)
#        this includes email(+EmailDetaiValue+), long text (+LongTextDetailValue+), 
#        s3 attachment parameters (+S3Attachment+)
#        and web urls (+WebUrlDetailValue+).
#      * The values containing dates are stored in +DateDetailValue+
#        (date_detail_values).
#      * The values containing integer data are stored in +IntegerDetailValue+
#        (+integer_detail_values+)
#      * The values for which multiple values exists (see +DetailValueProposition+)
#        are stored in +DdlDetailValue+ (+ddl_detail_values+)
#      
# *Fiedls*
# Contains following fields:
#   * id
#   * detail_id
#   * instance_id
#   * value
#   * type
#
# *Relationships*
#   belongs_to :instance
#   belongs_to :detail
#
class DetailValue <  ActiveRecord::Base
  
  belongs_to :instance
  belongs_to :detail
 
  attr_readonly :id,
                :detail_id,
                :instance_id
  
  validates_each :value, :on => :create do |rec, attr, value|
       
    instance = Instance.find(rec['instance_id'])
    entity = Entity.find(instance.entity_id)
    detail = Detail.find(rec['detail_id'])
    limit = EntityDetail.find(:first, :conditions => ["detail_id=? AND entity_id=?", detail.id, entity.id])
    
    limit = limit['maximum_number_of_values'] ?  limit['maximum_number_of_values'] : 1
    
    count = DetailValue.count(:conditions => ["instance_id=? AND detail_id=?", rec['instance_id'], detail.id])
    
    
    if count >= limit
      msg = "#{detail.name}[#{detail.id}] of #{entity.name}[#{entity.id}] cannot have more then #{limit} values"
      rec.errors.add detail.name, msg
    end
  end

  def self.format_detail(o)
    o[:value].to_s
  end

  def self.valid?(v)
    true
  end

  #called in to_form_row, to build the html element's id. This id is also used in Entity.save_entity to identify invalid fields.
  def form_field_id(i,o)
    entity = %Q{#{o[:form_id]}_#{o[:entity].name}}.gsub(/ /,"_")
    entity += "_"+detail.name+"["+i.to_s+"]"
  end
  
#  #FIXME: How to determine the value of detail_value?
#  def to_json(options = {})
#    json = JSON.parse(super(options))
#    
#    #json['value'] = ''
#    
#    replace_with_url(json, 'id', :DetailValue, options)
#    replace_with_url(json, 'detail_id', :Detail, options)
#    replace_with_url(json, 'instance_id', :Instance, options)
#    
#    
#    return json.to_json
#
#  end
end
