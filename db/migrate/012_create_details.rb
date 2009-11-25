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

class CreateDetails < ActiveRecord::Migration
  def self.up
    create_table :details, :force => true do |t|
    t.column :name,         :text
    t.column :data_type_id, :integer, :references => :data_types, :deferrable => true
    t.column :status_id,    :integer, :references => :detail_status, :deferrable => true
    t.column :database_id,  :integer, :references => :databases, :deferrable => true
  end
  end

  def self.down
    drop_table :details
  end
end
