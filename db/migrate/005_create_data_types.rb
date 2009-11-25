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

class CreateDataTypes < ActiveRecord::Migration
  def self.up
    create_table :data_types, :force => true do |t|
    t.column :name,       :text
    t.column :class_name, :text
    end



      DataType.create(:id => 1, :name => 'madb_short_text'     , :class_name =>  'SimpleDetailValue')
      DataType.create(:id => 2, :name => 'madb_long_text'      , :class_name =>  'LongTextDetailValue')
      DataType.create(:id => 3, :name => 'madb_date'           , :class_name =>  'DateDetailValue')
      DataType.create(:id => 4, :name => 'madb_integer'        , :class_name =>  'IntegerDetailValue')
      DataType.create(:id => 5, :name => 'madb_choose_in_list' , :class_name =>  'DdlDetailValue')
      DataType.create(:id => 6, :name => 'madb_email'          , :class_name =>  'EmailDetailValue')
      DataType.create(:id => 7, :name => 'madb_web_url'        , :class_name =>  'WebUrlDetailValue')
      DataType.create(:id => 8, :name => 'madb_file_attachment'  , :class_name =>  'FileAttachment')
      
    ActiveRecord::Base.connection.execute("select setval('data_types_id_seq',8);")

  end

  def self.down
    drop_table :data_types
  end
end
