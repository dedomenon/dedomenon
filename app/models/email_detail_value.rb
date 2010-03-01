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
#     Stores an email value for a +Detail+
#     See +DetailValue+ for further details.
#
class EmailDetailValue < DetailValue
	belongs_to :instance
	belongs_to :detail

#        def self.table_name
#            "detail_values"
#        end

  def to_form_row(i=0, o={})
     entity = %Q{#{o[:form_id]}_#{o[:entity].name}}.gsub(/ /,"_")
		 id = detail.name+"["+i.to_s+"]"
	   %Q{
     <input type="hidden" id="#{o[:entity].name}_#{detail.name}[#{i.to_s}]_id" name="#{detail.name}[#{i.to_s}][id]" value="#{self.id}">
     <tr><td>#{detail.name }:</td><td><input type="text" id ="#{entity}_#{id}_value"  name="#{detail.name+"["+i.to_s+"]"}[value]" value="#{value}" /></td></tr>
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
                  id: "#{form_field_id(i,o)}_id",
                  name:"#{form_field_name(i,o)}[id]",
                  value:"#{self.id}"}));

    var email_field =  new Y.TextField({
                  id: "#{form_field_id(i,o)}_value",
                  validator : Y.madb.get_detail_validator(#{detail.id}),
                  name:"#{form_field_name(i,o)}[value]",
                  value:"#{value}",
                  label:"#{form_field_label}"})
    email_field.on('clear', function(field) {
             field._fieldNode.removeClass('valid_form_value');
             field._fieldNode.removeClass('invalid_form_value');
             field._fieldNode.removeClass('unchecked_form_value');

    });
    fields.push(email_field);
    }
	end

  def self.format_detail(options)
     return "" if options[:value].nil?
     options[:format]=:html if options[:format].nil?
     case options[:format]
     when :html
      return %Q{<a href="mailto:#{options[:value]}">#{html_escape(options[:value])}</a>}
     else
      return options[:value]
     end
	end

# Description::
#     Returns whether object contains valid email address?
  def self.valid?(value, o={})
		if value.nil? or value=="" or value.match(/^[_\w-]+(\.[_\w-]+)*@[\w-]+(\.\w+)*(\.[a-z]{2,3})$/)
			return true
		end
		return false
	end
  def self.yui_formatter(h={})
    '"email"'
  end
end
