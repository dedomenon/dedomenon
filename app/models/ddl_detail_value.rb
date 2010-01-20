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
#     In MyOwnDB, any column (described by +Detail+) can have multiple values.
#     Like if you are talking about a column (that is, +Detail+) risk_level,
#     then it might have multiple values (high, low, medium, none). For that,
#     MyOwnDB uses +DetailValuePropositions+ (detail_value_propositions).
#     When data is entered against any column (+Detail+) which has option of 
#     multiple values, those value fields are contained in this object and in 
#     its underlying table +ddl_detail_values+. While the option for the values 
#     comes from +detail_value_propositions+
#     
# *Fields*
# Contains following fields:
#   * id
#   * detail_id
#   * instance_id
#   * detail_value_proposition_id
#
# *Relationships*
#   * belongs_to :instance
#   * belongs_to :detail
#   * belongs_to :detail_value_proposition

class DdlDetailValue < DetailValue

  belongs_to :instance
  belongs_to :detail
  belongs_to :detail_value_proposition
  
  attr_readonly :id,
                :detail_id,
                :instance_id
                
  
  validates_each :value, :on => :create do |rec, attr, value|
       
    instance = Instance.find(rec['instance_id'])
    entity = Entity.find(instance.entity_id)
    detail = Detail.find(rec['detail_id'])
    limit = EntityDetail.find(:first, :conditions => ["detail_id=? AND entity_id=?", detail.id, entity.id])
    
    
    limit = limit['maximum_number_of_values'] ?  limit['maximum_number_of_values'] : 1
    count = DdlDetailValue.count(:conditions => ["instance_id=? AND detail_id=?", rec['instance_id'], detail.id])
    
    
    if count >= limit
      msg = "#{detail.name}[#{detail.id}] of #{entity.name}[#{entity.id}] cannot have more then #{limit} values"
      rec.errors.add detail.name, msg
    end
  end
    

# Description::
#     Returns the underlying database table of the model
  def self.table_name
      "ddl_detail_values"
  end

# Description::
#     Returns the value.
#     As this is a choice in multiple propositions, it returns the value stored in the proposition linked by this DdlDetailValue. Returning the value of DdlDetailValue would return the id of the value proposition linked....
  def value
    detail_value_proposition.value
  end

 #  Description::
 #      Writes the value.
  def value=(i)
    write_attribute("detail_value_proposition_id",i)
  end

  # Description:
  # to_form_row format this detail value for display in in HTML form. For a DdlDetailValue, it is displayed in the form of a drop down list, with the current value being the option selection.
  def to_form_row(i=0, o={})
    propositions = detail.detail_value_propositions
    %Q{
    <input type="hidden" id="#{o[:entity].name}_#{detail.name}[#{i.to_s}]_id" name="#{detail.name}[#{i.to_s}][id]" value="#{self.id}">
    <tr><td>#{detail.name }:</td><td><select name="#{detail.name+"["+i.to_s+"]"}[value]"> #{ propositions.inject("") do |r,p|
        r<< %Q{<option #{(detail_value_proposition_id==p.id)?'selected="selected"':''} value="#{p.id}">#{p.value}</option>}
        end
        } </select></td></tr>}
  end

  def to_yui_form_row(i=0,o={})
    propositions = detail.detail_value_propositions
    choices = propositions.collect{|p|  %Q{ { value : "#{ p.id }" ,label:  "#{p.value}"  } }  }.join(',')
    choices = "[" + choices + "]"
    	   %Q{
    fields.push( new Y.HiddenField({
                  id: "#{o[:entity].name}_#{detail.name}[#{i.to_s}]_id",
                  name:"#{detail.name}[#{i.to_s}][id]",
                  value:"#{self.id}"}));
    fields.push( new Y.SelectField({
                  name:"#{detail.name+"["+i.to_s+"]"}[value]",
                  choices: #{choices},
                  label:"#{detail.name }"}));

     }
	end

  # *Description*
  #     Format detail value for display. 
  #     the parameter format was instroduced for the export to csv, for which html_escape should not be called
	def self.format_detail(options)
     return "" if options[:value].nil?
     options[:format]=:html if options[:format].nil?
     case options[:format]
     when :html
       return html_escape(options[:value])
      else
        return options[:value]
      end
    end

  def self.valid?(value, o={})
    return false if value==-1
    #no further validation if detail not passed
    return true if o[:detail].nil?
    detail = o[:detail]
    return false unless detail.value_propositions.collect{|p| p.id}.include? value
    return true
  end
    
end
