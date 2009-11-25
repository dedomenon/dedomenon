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
#   For the fields (see +Detail+) that contain multiple values, those multiple
#   values are encapsulated by the class and its underlying table 
#   (+detail_value_propositions+)
#   
# *Fields*
# Contains following fields:
#   * id
#   * detail_id
#   * value
#
# *Relationships*
#   * belongs_to :detail
#   * has_many :ddl_detail_values
#
class DetailValueProposition < ActiveRecord::Base
 
  belongs_to :detail
  has_many :ddl_detail_values
  
  attr_readonly :id,
                :detail_id

  # *Description*
  #     Format detail value for display. For a value proposition we simply html_escape the value stored.
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
#    replace_with_url(json, 'id', :DetailValueProposition, options)
#    replace_with_url(json, 'detail_id', :Detail, options)
#    
#    return json.to_json
#  end
end
