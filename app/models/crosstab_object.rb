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

# This class only exists to access its connection as in 
# CrosstabObject.connection.quote_string(params["#{@list_id}_order"].to_s)
#
class CrosstabObject < ActiveRecord::Base

    # FIXME: we map it to the details table, but we'll never use it.
   def self.table_name
   	"details"
  end

  # FIXME: we map it but it's never used I think.
  def self.inheritance_column
    "crosstab_inheritance_column"
  end
#  def self.serialize_columns(a)
#    a.each do |c|
#      m = %{ def #{c} 
#               str = read_attribute(:#{c}) 
#               return "" if str.nil?
#             end }
#      self.class_eval(m)
#    end
#  end
  def self.define_accessors(all_details, serialized)
    all_details.each do |c|
      puts "defining #{c.madb_sanitize} for #{c}"
      m = %{ def #{c.madb_sanitize} 
               str = self.attributes[#{c.dump}] 
      }
      if serialized.include?(c)
        m+= %{ return "" if str.nil?
                return YAML.load(str) 
            }
      end 
               #{serialized.include?(c) ? "return YAML.load(str)" : "return str"}
               
      m+=" end "
               #{serialized.include?(c) ? "puts 'return emtpy string' and return "" if str.nil?; return YAML.load(str)" : "return str"}
      self.class_eval(m)
    end
  end
end
