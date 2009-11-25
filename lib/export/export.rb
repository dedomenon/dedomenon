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

require 'S3'
require "ruby-debug"
Debugger.start
#TODO: set instance#detail_value to return nil if no value (line 52 in app/model/instance.rb)
#DEPLOYMENT: add self.export_directory in config/environments/development.rb

require "export/postgres"
include Postgresql
s3_conn = S3::AWSAuthConnection.new(AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
s3_generator = S3::QueryStringAuthGenerator.new(AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
db_id=202

#create directory for saving attached files
FileUtils.mkdir_p(MadbSettings.export_directory+"/"+db_id.to_s+"/files/")

def rename_file(f, suffix)
  f.sub(Regexp.new(File.extname(f)), '')+'_'+suffix.to_s+File.extname(f)
end


db = Database.find db_id
db.entities.each do |entity|
  table_name = entity.name
  columns = []
  columns.push({ :column_name => "id" ,:detail_name => "id", :myowndb_type => "int", :number_of_values => 1, :primary_key => true})
  entity.ordered_details.each do |d|
    columns.push({ :column_name => d.name,:detail_name => d.name, :myowndb_type => d.data_type.name, :number_of_values => d.maximum_number_of_values})
  end

  entity.relations_to_children.each do |r|
    #if from one to many, pass as fk is in other side
    next if r.parent_side_type.name=="one" and r.child_side_type.name=="many"
    #if from one to one, add it as we are at parent side
    if r.parent_side_type.name=="one" and r.child_side_type.name=="one"
      columns.push({ :column_name => r.child.name+"_id", :detail_name => r.child.name, :myowndb_type => "madb_foreign_key", :number_of_values => 1})
#    #if from many to one, add it as foreign key is here
    elsif r.parent_side_type.name=="many" and r.child_side_type.name=="one"
      columns.push({ :column_name => r.child.name+"_id", :detail_name => r.child.name, :myowndb_type => "madb_foreign_key", :number_of_values => 1})
#    #if from many to many, add a table and constraints
    elsif r.parent_side_type.name=="many" and r.child_side_type.name=="many"
      create_table( :table => r.parent.name+"2"+r.child.name , :columns => [{ :column_name => r.parent.name+"_id", :myowndb_type => "madb_integer", :number_of_values => 1},{ :column_name => r.child.name+"_id", :myowndb_type => "madb_integer", :number_of_values => 1}])
    end
  end    
  entity.relations_to_parents.each do |r|
    #if from one to many, pass as fk is in other side
    if r.parent_side_type.name=="one" and r.child_side_type.name=="many"
      columns.push({ :column_name => r.parent.name+"_id",:detail_name =>r.parent.name, :myowndb_type => "madb_foreign_key", :number_of_values => 1})
    end
  end
  create_table( :table => table_name, :columns => columns )

  entity.instances.each do |instance|
    data = {}
    data[entity.name]||={:columns => [{ :column_name => "id", :myowndb_type => "int", :number_of_values => 1, :values => [ instance.id ] }]}
    instance.links_to_children.each do |l|
      next if l.relation.parent_side_type.name=="one" and l.relation.child_side_type.name=="many"
      #if from one to one, add it as we are at parent side
      if l.relation.parent_side_type.name=="one" and l.relation.child_side_type.name=="one"
        data[entity.name][:columns].push({ :column_name => l.relation.child.name+"_id",:detail_name => l.relation.child.name, :myowndb_type => "madb_foreign_key", :number_of_values => 1, :values => [ l.child.id ] })
#    #if from many to one, add it as foreign key is here
      elsif l.relation.parent_side_type.name=="many" and l.relation.child_side_type.name=="one"
        data[instance.entity.name][:columns].push({ :column_name => l.relation.child.name+"_id", :detail_name => l.relation.child.name, :myowndb_type => "madb_foreign_key", :number_of_values => 1, :values => [ l.child.id ]})
      elsif l.relation.parent_side_type.name=="many" and l.relation.child_side_type.name=="many"
        relations_data||={}
        relations_data[l.relation.parent.name+"2"+l.relation.child.name]||={:columns => []}
        relations_data[l.relation.parent.name+"2"+l.relation.child.name][:columns].concat( [{ :column_name => l.relation.parent.name+"_id", :detail_name =>l.relation.parent.name , :myowndb_type => "madb_integer", :number_of_values => 1, :values => [ instance.id ]},{ :column_name => l.relation.child.name+"_id", :detail_name =>l.relation.child.name, :myowndb_type => "madb_integer", :number_of_values => 1, :values => [ l.child.id]}])
        handle_data(relations_data)
        relations_data[l.relation.parent.name+"2"+l.relation.child.name]=nil
      end
    end

    instance.links_to_parents.each do |l|
      #if from one to many, pass as fk is in other side
      if l.relation.parent_side_type.name=="one" and l.relation.child_side_type.name=="many"
        data[entity.name][:columns].push({ :column_name => l.relation.parent.name+"_id", :detail_name => l.relation.parent.name, :myowndb_type => "madb_foreign_key", :number_of_values => 1, :values => [ l.parent.id ]})
      end
    end

    entity.ordered_details.each do |d|
      data[entity.name]||=[]
      case d.data_type.name
      when "madb_choose_in_list"
        proposition = DdlDetailValue.find(:first, :conditions => ["instance_id = ? and detail_id = ?", instance.id, d.detail_id])
        if proposition.nil? 
          proposition_id= nil
        else
          proposition_id = proposition.detail_value_proposition_id
        end
        values = [proposition_id]
      when "madb_s3_attachment"
        file_details =instance.detail_value(d.name)
        exported_file = MadbSettings.export_directory+"/"+db.id.to_s+"/files/"+ file_details[:filename]
        i=1
        while File.exist?(exported_file)
          exported_file = rename_file(exported_file,i)
          i+=1
        end
        f = s3_conn.get(MadbSettings.s3_bucket_name , instance.detail_value(d.name)[:s3_key])
        open(exported_file, "wb") { |file|
          file.write(f.object.data)
        }
        values = [ exported_file.sub(Regexp.new(MadbSettings.export_directory),"") ]
      else
        values = [ instance.detail_value(d.name) ]
      end
      data[entity.name][:columns].push({ :column_name => d.name, :myowndb_type => d.data_type.name, :number_of_values => d.maximum_number_of_values, :values => values })
    end
    handle_data( data )
  end
end

db.details.each do |detail|
  h = { :name => detail.name, :type => detail.data_type.name }
  propositions = []
  if detail.data_type.name == 'madb_choose_in_list'
    detail.detail_value_propositions.each do |p|
      propositions.push({ :id => p.id, :value => p.value})
    end
  end
  h.update({ :propositions => propositions })
  handle_detail ( h  )

end


open(MadbSettings.export_directory+"/"+db.id.to_s+"/"+db.name+".sql", "w+") { |file|

  @tables_queries.each do |q|
    file.write q 
  end
  @data_queries.each do |q|
    file.write q 
  end

  @constraints_queries.each do |q|
    file.write q 
  end
}
