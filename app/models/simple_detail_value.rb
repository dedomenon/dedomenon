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
#     The value of each +Detail+ is stored in this object and its underlying
#     table +detail_values+
#     See +DetailValue+ for further details.
#
class SimpleDetailValue <  DetailValue
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

  def to_form_row(i=0,o={})
	   %Q{
     <input type="hidden" id="#{o[:entity].name}_#{detail.name}[#{i.to_s}]_id" name="#{detail.name}[#{i.to_s}][id]" value="#{self.id}">
     <tr><td>#{detail.name }:</td><td><input type="text" name="#{detail.name+"["+i.to_s+"]"}[value]" value="#{value}" /></td></tr>}
	end
end

