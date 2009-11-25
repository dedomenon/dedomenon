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
#     Whenever a +Detail+ is created, it can be used with mulitple entitites.
#     entitites2details links a detail to an entity.
#   
# *Fields*
#     Has following fields:
#       * id
#       * entity_id
#       * detail_id
#       * status_id
#       * displayed_in_list_view
#       * maximum_number_of_values
#       * display_order
#
# *Relationships*
#       * belongs_to :detail
#       * belongs_to :entity
#
#
#
#DEPRECATED!!!
#use EntityDetail rather than this
class Entities2Detail < ActiveRecord::Base
  belongs_to :detail
  belongs_to :entity

  # The database table contains the status_id field that should be linked
  # with the detail_status table's id field, but there is no relationship
  # either at the table level or at the object level. I am adding
  # The relationships at both levels.
  # Mohsin Hijazee
  # December 07 2007
  belongs_to :detail_status
  def self.table_name
    "entities2details"
  end
end

# This was introduced in an upgrade of Rails, where it complained that the class Entities2detail was not defined
# The simplest solution was to define it here. It is never used in the code though, as only Entities2Detail was used before this upgrade.
# Entities2detail should never be used!
Entities2detail = Entities2Detail
