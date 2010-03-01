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
#     The integer values for a +Detail+ are stored in this object and its 
#     underlying table +integer_detail_values+
#     See +DetailValue+ for reference.
#     
# *Fields*
#   * id
#   * detail_id
#   * instance_id
#   * value
#     
# *Relationships*
#   * belongs_to :instance
#   * belongs_to :detail
#
#
require 'entities2detail.rb'

class IntegerDetailValue < DetailValue


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
    
    count = IntegerDetailValue.count(:conditions => ["instance_id=? AND detail_id=?", rec['instance_id'], detail.id])
    
    
    if count >= limit
      msg = "#{detail.name}[#{detail.id}] of #{entity.name}[#{entity.id}] cannot have more then #{limit} values"
      rec.errors.add detail.name, msg
    end
    

  end

  def self.table_name
            "integer_detail_values"
        end
	
  def to_form_row(i=0, o={})
        
     entity = %Q{#{o[:form_id]}_#{o[:entity].name}}.gsub(/ /,"_")
		 id = detail.name+"["+i.to_s+"]"
	   %Q{
     <input type="hidden" id="#{o[:entity].name}_#{detail.name}[#{i.to_s}]_id" name="#{detail.name}[#{i.to_s}][id]" value="#{self.id}">
     <tr><td>#{detail.name }:</td><td><input type="text"  id ="#{entity}_#{id}_value" name="#{detail.name+"["+i.to_s+"]"}[value]" value="#{value}" /></td></tr>
		   <script type="text/javascript">
			    new DetailWatcher("#{entity}_#{id}", "#{detail.id}");	
		   </script>
		 }
  end

  def to_yui_form_row(i=0,o={})
    entity = %Q{#{o[:form_id]}_#{o[:entity].name}}.gsub(/ /,"_")
		 id = detail.name+"["+i.to_s+"]"
	   %Q{
    fields.push( new Y.HiddenField({
                  id: "#{o[:entity].name}_#{detail.name}[#{i.to_s}]_id",
                  name:"#{form_field_name(i,o)}[id]",
                  value:"#{self.id}"}));
    var integer_field=  new Y.TextField({
                  id: "#{form_field_id(i,o)}_value",
                  name:"#{form_field_name(i,o)}[value]",
                  validator : Y.madb.get_detail_validator(#{detail.id}),
                  value:"#{value}",
                  label:"#{detail.name }"});
    integer_field.on('clear', function(field) {
             field._fieldNode.removeClass('valid_form_value');
             field._fieldNode.removeClass('invalid_form_value');
             field._fieldNode.removeClass('unchecked_form_value');

    });
    fields.push(integer_field);

     }
	end

  def self.valid?(value, o={})
    if value.nil? or value.match(/^\d*$/)
      return true
    end
    return false
  end
  
#  def to_json(options = {})
#    
#    json = JSON.parse(super(options))
#    
#    replace_with_url(json, 'id', :DetailValue, options)
#    replace_with_url(json, 'detail_id', :Detail, options)
#    replace_with_url(json, 'instance_id', :Instance, options)
#    
#    return json.to_json
#  end

end
