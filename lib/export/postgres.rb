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

module Postgresql

  attr :tables_queries
  attr :constraints_queries
  attr :data_queries

  def create_table( o = {} )
    # :table : table name
    # :columns : [ { :name => "column_name", :myowndb_type => "date", :number_of_values => 1}] 
    # :foreign_keys : [ { :column => "column_name", :references => { :table => "table_name", :column => "column_name" } }]
    # :primary_key : { :name => "id", :last_value => 43234 }
    fields = ""
    @constraints_queries||=[]
    o[:columns].each do |col|
      fields += %{ "#{col[:column_name]}" #{native_type(col)} #{col[:primary_key] ? "PRIMARY KEY" : "" },}
      if col[:myowndb_type]=="madb_foreign_key"
        @constraints_queries||=[]
        query=%{alter table "#{o[:table]}" ADD CONSTRAINT "fk_#{o[:table]}_#{col[:column_name]}" FOREIGN KEY("#{col[:column_name]}") REFERENCES "#{col[:detail_name]}"(id);}
        @constraints_queries.push query
      elsif col[:myowndb_type]=="madb_choose_in_list"
        @constraints_queries||=[]
        query=%{alter table "#{o[:table]}" ADD CONSTRAINT "fk_#{o[:table]}_#{col[:column_name]}" FOREIGN KEY("#{col[:column_name]}") REFERENCES "#{col[:detail_name]}_propositions"(id);}
        @constraints_queries.push query
      end
    end
    fields.chop!
    @tables_queries||=[]
    @tables_queries.push %{create table "#{o[:table]}" ( #{ fields } );}
  end

  def handle_detail( o={})
    # :name : detail name
    # :type : data_type
    # :propositions : value propositions

    @tables_queries||=[]
    return if o[:type]!="madb_choose_in_list"
    @tables_queries.unshift %{create table "#{o[:name]}_propositions" (id int primary key, value text);}
    o[:propositions].each do |p|
      @data_queries||=[]
      @data_queries.push %{insert into "#{o[:name]}_propositions" (id, value) VALUES (#{p[:id]},'#{p[:value]}');}
    end
    

  end

  def handle_data(data)

    fields=values=""
    data.each_pair do |table, columns|
      columns[:columns].each do |c|
        next if c[:values][0].nil? # was : to_s.length==0
        fields+=%{"#{c[:column_name].to_s}",}
        #FIXME: find another way to quote values
        values+=%{#{Instance.quote(c[:values][0].to_s)},}
      end
      @data_queries||=[]
      @data_queries.push %{insert into "#{table}" ( #{fields.chop}) VALUES (#{values.chop}) ;}
    end
  end

  def native_type( col )
    case col[:myowndb_type]
      when "madb_date"
        return "timestamp"
      when "madb_integer"
        return "bigint"
      when "madb_long_text"
        return "text"
      when "madb_short_text"
        return "text"
      when "madb_email"
        return "text"
      when "madb_web_url"
        return "text"
      when "madb_s3_attachment"
        return "text"
      when "madb_choose_in_list"
        return %{int}
      when "madb_foreign_key"
        #here we create foreign keys for linking tables
        return %{int}
      #if it is not a known type, return the type itself, it can be a native database type (used for primary keys eg)
      else
        return  col[:myowndb_type]
      end
  end
end
