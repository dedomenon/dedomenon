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
#   Contains the long text value. See +DetailValue+
#
class LongTextDetailValue < DetailValue
#	belongs_to :instance
#	belongs_to :detail
#	def self.table_name
#	   "detail_values"
#	end
	
	def to_form_row(i=0,o={})
	   %Q{
     <input type="hidden" id="#{o[:entity].name}_#{detail.name}[#{i.to_s}]_id" name="#{detail.name}[#{i.to_s}][id]" value="#{id}">
     <tr><td>#{detail.name }:</td><td><textarea cols="30" rows="10" name="#{detail.name+"["+i.to_s+"]"}[value]">#{html_escape(value)}</textarea></td></tr>}
	end
	def to_yui_form_row(i=0,o={})
	   %Q{
    fields.push( new Y.HiddenField({
                  id: "#{form_field_id(i,o)}_id",
                  name:"#{form_field_name(i,o)}[id]",
                  value:"#{self.id}"}));
    fields.push( new Y.TextareaField({
                  id: "#{form_field_id(i,o)}_value",
                  name:"#{form_field_name(i,o)}[value]",
                  value:'#{escape_javascript(value)}',
                  label:'#{escape_javascript(form_field_label)}'}));
    }
	end
	def self.format_detail(options)
           s = options[:value]
           s = html_escape(options[:value]) if options[:format]=='html'

	   return s
  end
end
