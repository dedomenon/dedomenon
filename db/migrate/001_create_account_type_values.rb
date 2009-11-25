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

class CreateAccountTypeValues < ActiveRecord::Migration
  def self.up
    create_table :account_type_values, :force => true do |t|

      # Here we are using the Foreign Key Migrations plugin available from
      # http://www.redhillonrails.org/. This plug in is installed in
      # vendor/plugin directory. if you see any column colname_id with options
      # of :references, on_update then you can safely assume that this plugin
      # is being utilized. The benifit of this plugin is that it generates
      # The foriegn key constrainst automatically which at time time of writing,
      # Rails does not.
      # Mohsin Hjazee on 07 December 2007
      t.column :account_type_id, :integer #, :references => :account_types
      t.column :detail,          :text
      t.column :value,           :text
    end
  end

  def self.down
    drop_table :account_type_values
  end
end