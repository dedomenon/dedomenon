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

class CreateDetailStatus < ActiveRecord::Migration
  def self.up
    create_table :detail_status, :force => true do |t|
      t.column :name, :text
    end
    DetailStatus.create( :id => 1, :name => 'active')
    DetailStatus.create( :id => 2, :name => 'inactive')
    ActiveRecord::Base.connection.execute("select setval('detail_status_id_seq',2);")
  end

  def self.down
    drop_table :detail_status
  end
end
