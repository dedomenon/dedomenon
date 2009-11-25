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
#   Stores a web url value for a +Detail+ in +DetailValue+
#   See +DetailValue+ for details.
#
class WebUrlDetailValue < DetailValue
#	belongs_to :instance
#	belongs_to :detail

#	def self.table_name
#	   "detail_values"
#	end

  def self.format_detail(options)
     return "" if options[:value].nil?
     options[:format]=:html if options[:format].nil?
     case options[:format]
     when :html
       return %Q{<a TARGET="_blank" href="#{options[:value]}">#{html_escape(options[:value])}</a>}
     else
      return options[:value]
     end
  end

  def to_form_row(i=0,entity='')
	   %Q{<tr><td>#{detail.name }:</td><td><input type="text" name="#{detail.name+"["+i.to_s+"]"}[value]" value="#{value=~/http(s)?:\/\// ? value : "http://" + value.to_s}" /></td></tr>}
	end

end
