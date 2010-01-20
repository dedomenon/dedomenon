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
include ERB::Util
# *Description*
#   Stores the date values for a +Detail+. See +DetailValue+
#     
# *Fields*
# Contains following fields:
#   * id
#   * detail_id
#   * instance_id
#   * value
# 
# *Relations*
#  * belongs_to :instance
#  * belongs_to :detail
#

class DateDetailValue < DetailValue
  
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
    
    count = DateDetailValue.count(:conditions => ["instance_id=? AND detail_id=?", rec['instance_id'], detail.id])
    
    
    if count >= limit
      msg = "#{detail.name}[#{detail.id}] of #{entity.name}[#{entity.id}] cannot have more then #{limit} values"
      rec.errors.add detail.name, msg
    end
    

  end

  def self.table_name
            "date_detail_values"
        end

  # *Description*
  #  Perhaps convertes the data of the object in tabular format with check boxes.
  
  def to_form_row(i=0, o={})
      # A detail watcher is watching all changes, activation and bluring occuring to a field in a form. It will then validate and highlight incorrect values. See public/javascript/madb.js
     entity = %Q{#{o[:form_id]}_#{o[:entity].name}}.gsub(/ /,"_")
     # id is a string different for each date detail in this instance. This lets us distinguish them in the form.
		 id = detail.name+"["+i.to_s+"]"
	   %Q{
     <input type="hidden" id="#{o[:entity].name}_#{detail.name}[#{i.to_s}]_id" name="#{detail.name}[#{i.to_s}][id]" value="#{self.id}">
     <tr><td>#{detail.name}:</td><td><input detail_id="#{detail.id}" class="unchecked_form_value" type="text" id ="#{entity}_#{id}_value" name="#{id}[value]" value="#{value ? value.strftime("%Y-%m-%d %H:%M:%S"):Time.now.strftime("%Y-%m-%d %H:%M:%S")}" /></td></tr>
		   <script type="text/javascript">
			    new DetailWatcher("#{entity}_#{id}", "#{detail.id}");
		   </script>
		 }
	end

  def to_yui_form_row(i=0,o={})
    	   %Q{
    fields.push( new Y.HiddenField({
                  id: "#{o[:entity].name}_#{detail.name}[#{i.to_s}]_id",
                  name:"#{detail.name}[#{i.to_s}][id]",
                  value:"#{self.id}"}));
    fields.push( new Y.TextField({
                  id: "#{form_field_id(i,o)}_value",
                  name:"#{detail.name+"["+i.to_s+"]"}[value]",
                  label:"#{detail.name }"}));

     }
	end
  # *Description*
  #     Returns whether the date detail value contained is valid or not.
  # *Workflow*
  #     Uses the <tt>DateTime.parse()</tt> function to accomplish the task.
  def self.valid?(value, o={})
		begin
			DateTime.parse(value)
			return true
		rescue ArgumentError,TypeError
		end
		return false
end

  # *Description*
  #     Format detail value for display. For a date detail we simply html_escape the value stored.
  def self.format_detail(options)
    if options[:format].to_s == 'csv'
      return options[:value]
    else
	   return html_escape(options[:value])
    end
  end
  
#  def to_json(options = {})
#    
#    json = JSON.parse(super(options))
#    
#    replace_with_url(json, 'id', :DateDetailValue, options)
#    replace_with_url(json, 'detail_id', :Detail, options)
#    replace_with_url(json, 'instance_id', :Instance, options)
#    
#    
#    return json.to_json
#    
##    json = super.to_json(options)
##    base_url = 'http://localhost:3000/'
##    #FIXME: Yet the URL is to be decided i.e. the REST position
##    self_url = '"' + base_url + "instances/#{instance_id}/details/#{detail_id}/date_detail_values/#{id}" + '"'
##    
##    json.gsub!(/("id":\s+\d+)/, '"url": ' + self_url)
##    
##    detail_url = '"' + base_url + "details/#{detail_id}" + '"'
##    instance_url = '"' + base_url + "instances/#{instance_id}"
##          
##    json.gsub!(/("detail_id":\s+\d+)/, detail_url)
##    json.gsub!(/("instance_id":\s+\d+)/, instance_url)
##    
##    return json
#  end
end
