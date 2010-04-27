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
#     The +Entity+ class is the object oriented layer on top of the underlying
#     +entities+ table. +entities+ table stores the table of a database in
#     MyOwnDB. The fields are stored in the +details+ table.
#     See Database class for further reference.
#     
# *Fields*
#     Has following fields:
#       * id
#       * database_id
#       * name
#       * has_public_form
# *Relations*
#     	* has_and_belongs_to_many :details, :join_table => "entities2details"
#       * has_many :relations_to_children, :class_name => "Relation",  :foreign_key => "parent_id"
#	* has_many :relations_to_parents, :class_name => "Relation",  :foreign_key => "child_id"
#       * has_many :entity_details
#       * has_many :instances, :dependent => :destroy
#       * belongs_to :database
#
include FormHelpers 
class Entity < ActiveRecord::Base
  has_and_belongs_to_many :details, :join_table => "entities2details"
  #has_and_belongs_to_many :entities, :join_table => "relations", :foreign_key => "parent_id", :association_foreign_key => "child_id"
  has_many :relations_to_children, :class_name => "Relation",  :foreign_key => "parent_id"
  has_many :relations_to_parents, :class_name => "Relation",  :foreign_key => "child_id"
  has_many :entity_details
  has_many :instances, :dependent => :destroy
  belongs_to :database
  
  validates_uniqueness_of :name
  attr_readonly   :id,
                  :database_id
                
  attr_protected  :details_url,
                  :instances_url,
                  :relations_url

  # Returns the list ordered according to the display order specified by the administrator in the admin part of the application
  def ordered_details
    # when iterating, we need to use detail_id to get the detail's id.
    self.details.sort{|a,b| a.display_order<=>b.display_order}
  end

  # Returns the list of details to be displayed in list view. The display in list views can be toggled in the admin part.
  #Should go with details REST 
  def details_in_list_view
    ordered_details.sort{|a,b| a.display_order<=>b.display_order}.delete_if{|d| d.displayed_in_list_view!='t'}
  end

  # returns true if this entity has at least one detail of type file attachment
  def has_file_attachment_detail?
    detail_types = details.collect{|d| d.data_type.name}.uniq
    if detail_types.include?('madb_s3_attachment') or detail_types.include?('madb_file_attachment')
      return true
    else
      return false
    end
    
  end
  # Return a hash with 
  # * key = detail_name
  # * value = detail
  def details_hash
    @details_hash||=entity_details.collect{|ed| ed.detail}.inject({}){|acc,i| acc.merge( { i.name => i}) }
  end
  def details_names
    @details_names||=details_hash.collect{|name,d| name}
  end

#filters details_hash and only keeps details that have their value serialized
  def serialized_details
    @serialized_details||=details_hash.reject{|name,d| not ["FileAttachment"].include? d.data_type.class_name}
  end

#returns an array of details whose values are serialized.
  def serialized_details_names
    @serialized_details_names||=serialized_details.collect{|name,d| name}
  end
  #
  # Cleans params to only key values to be assigned to detail_values related to this entity
  def clean_params(h)
     h.reject{|k,v| not details.collect{|d| [d.name, d.hashed_name ]}.flatten.include?(k)}
  end

  # Build params to pass to save_entity, used in hash based instanciation (ie not in the code handling the form submission
  def self.build_params(h)
    h.inject({}) do |acc,i|
      acc.merge({ i[0] => { "0" => {"value" => i[1] }}})
    end
  end

  def self.instanciate(id, h)
    e = Entity.find id
    h.each do |k,v|
      #ignore inexisting details passed
      next unless e.details_hash.keys.include? k
      #translate the ddl value to the value proposition's id
      if v!="" and (a=e.details_hash[k].detail_value_propositions).size>0
        proposition = a.reject{|i| i.value!=v}[0]
        if proposition.nil?
          #proposition is not found, set value to -1 so it will be 
          #detected as invalid in save_entity
          h[k]=-1
        else
          h[k]=proposition.id 
        end
      end
    end
    p = build_params(h)
    p["entity"]=id
    save_entity(p)
  end

  def self.save_entity(params)
    instance=nil
    id = params["instance_id"].to_i
    form_id = params[:form_id]
    ret = true
    detail_saved = false
    invalid_list = []
    detail_values = [] # used to keep all detail_value that we saved, and call destroy on s3 attachments if needed
    
    begin
      Entity.transaction do
        entity = Entity.find params["entity"]
        params=entity.clean_params(params)
      # Negative IDs are used for creating the instances
      if id>0
        instance = Instance.find(id)
      else
        instance = Instance.new
        instance.entity=entity
        instance.save
       end
	
        # We pick all the details of the entity
        #FIXME: This code uses EntityDetail class
        entity.entity_details.each  do |entity_detail|
          
          detail = entity_detail.detail
          #accept names based on the detail's name or its hash
          values = params[detail.name] || params[detail.hashed_name]
          values.each do |i,value|
            # if the value id is not provided, that means
            # the underlying DetailValue does not exists and we need to create
            # it. This block assigns the variable detail_value
            if value["id"].nil? or value["id"]==""
                
              # However, if the value is not preset, Sorry! Move next because
              # we do not insert empty values.
              if value["value"].nil? or value["value"]=="" or ( value["value"].respond_to?( :original_filename) and value["value"].original_filename=="")
                next
              end
              
              # Crucial!
              # * Get the class from the datatype.
              # * Create an instance of that dataype
              # * Set the value
              # * Connect to the instance
              detail_value_class = class_from_name(detail.data_type.class_name)
              detail_value = detail_value_class.new
              
              # This generates error! AssociationTypeMismatch by detail=
              #detail_value.detail = detail # Detail.find(:all, "name='#{detail.name}'")[0]
              
              # Therefore, this is the hack around!
              detail_value.detail_id = detail['id']
              detail_value.instance_id = instance['id']
              
              
              # Otherwise, if the id is present, we need to updat that!
            else
              
              # We pick the class for the detail.
              detail_value_class = class_from_name(detail.data_type.class_name)
		
              # if the value is left blank, we would be deleting the detail
              # of that ID.
              if value["value"]==""
                detail_value_class.delete(value["id"])
                next
              end
              # Pick the detail value of that class by the ID given
              detail_value= detail_value_class.find(value["id"])
            end
            # The variable detail_value is now assigned

            begin
              # If the provided value is not valid, then the return value would
              # be false and we push the detail in the invalid_list
              if ! detail_value_class.valid?(value["value"], :detail => detail)
                ret = false
                invalid_list.push(form_field_id(i, {:form_id => form_id, :entity => entity, :detail => detail})+"_value") 
              end
            rescue Exception => e
              #this rescue is for detail_values classes not implementing self.valid?
            end
	
            # If we had any invalide field, we simply do not
            # save.
          
            next if invalid_list.length>0
            
            # Crucial!
            # * Pick the field value
            # * Save it
            # * Yes, the detail saved!
            # * Save it in the list of saved detail values
            detail_value.value=value["value"]
            detail_value.save
            detail_saved = true
            detail_values.push detail_value
            
          end if params[detail.name] or params[detail.hashed_name]  # end of do block
      
        end

        #raise exception to rollback if necessary
	raise "invalid form" if !ret
	raise "no detail saved" if !detail_saved
		
      end

    # If any trouble, we do a bit of cleanup!
    rescue Exception => e
      #breakpoint "exception"
      #flash["error"] = t("madb_error_creating_instance")
      if e.message=="invalid form"
        detail_values.each do |dv|
          dv.destroy if dv.detail.data_type.name == "madb_s3_attachment"
        end
        return [ nil, invalid_list]
      elsif e.message=="no detail saved"
        raise e #if RAILS_ENV=="production"
      end
      #we should raise other exceptions too!
    end
    return  [ instance , []]
  end
  #returns arrays of details names
  def details_not_displayed_in_list
    init_details_display_lists unless @details_not_displayed_in_list
    @details_not_displayed_in_list
  end
  #returns arrays of details
  def details_displayed_in_list
    init_details_display_lists unless @details_not_displayed_in_list
    @details_displayed_in_list
  end
  def init_details_display_lists
    @details_not_displayed_in_list = []
    @details_displayed_in_list = []
    self.details.sort{ |a,b| a.name <=>b.name }.each do |detail|
      if detail.displayed_in_list_view=='f'
        @details_not_displayed_in_list.push detail.name
        next
      end
      @details_displayed_in_list.push detail
    end
  end
  def displayed_in_list?(detail)
    @details_displayed_in_list.include? detail
  end
  
  def crosstab_query(h = {})
    return @crosstab_elements if @crosstab_elements
    entity_id = self.id
    defaults = { :display => "detail" }
    not_in_list_fields = []
    details_kept = []

    options = defaults.update h
    details_select = ""
    as_string = "id int "
    
    ordinal = 1
    self.ordered_details.each do |detail|
      if detail.displayed_in_list_view=='f'
        not_in_list_fields.push detail.name
        next if options[:display]=="list"
      end
      details_kept.push detail
      #'select name from (select 1 as id , ''contract_description'' as name UNION select 2 as id , ''contract_price'' as name  UNION select 3 as id ,''contractors_name'' as name UNION select 4 as id ,''telephone'' as name) as temporary_table'
      #details_select += " UNION select #{ordinal} as id, E''#{Entity.connection.quote_string(detail.name)}'' as name"
      details_select += " UNION select #{ordinal} as id, E'#{Entity.connection.quote_string(detail.name)}' as name".gsub(/'/, "''").gsub(/\\/,"\\\\\\\\");
      ordinal = ordinal + 1
      case detail.data_type.name
      #  when "short_text"
      #  when "long_text"
      #  when "date"
         when "madb_integer"
          as_string += ",  #{Entity.connection.quote_column_name(detail.name)} bigint "
      #  when "choose_in_list"
         else
          as_string += ",  #{Entity.connection.quote_column_name(detail.name)} text "
      end
    end
    if details_select.length==0
      return nil
    else
      details_select = "select name from (#{details_select}) as temporary_table"
      h = { :values_query =>"select distinct on (i.id, d.name) i.id, d.name as name, dv.value from instances i join detail_values dv on (dv.instance_id=i.id) join details d on (d.id=dv.detail_id) where i.entity_id=#{entity_id}
      union select distinct on (i.id, d.name) i.id, d.name as name, dv.value::text from instances i join date_detail_values dv on (dv.instance_id=i.id) join details d on (d.id=dv.detail_id)  where i.entity_id=#{entity_id}
      union select distinct on (i.id, d.name) i.id, d.name as name, dv.value::text from instances i join integer_detail_values dv on (dv.instance_id=i.id) join details d on (d.id=dv.detail_id) where i.entity_id=#{entity_id}
      union select distinct on (i.id, d.name) i.id, d.name as name, pv.value from instances i join ddl_detail_values dv join detail_value_propositions pv on (pv.id=dv.detail_value_proposition_id)  on (dv.instance_id=i.id) join details d on (d.id=dv.detail_id)  where i.entity_id=#{entity_id} order by id, name",
      :details_query => details_select.sub!(/UNION/,""),
      :as_string => "#{as_string}" }
      #[ "crosstab('#{h[:values_query]}', '#{h[:details_query]}') as (#{h[:as_string]})", not_in_list_fields ]
      @crosstab_elements =  { 
        :query => "crosstab(E'#{h[:values_query]}', E'#{h[:details_query]}') as (#{h[:as_string]})", 
        :not_in_list_view => not_in_list_fields, 
        :ordered_fields => details_kept.sort{|a,b| a.display_order<=>b.display_order}.collect{|d| d.name }}
    end
  end

  # returns page_number to display according to highlight value or the requested page
  def page_number(crosstab_query=nil, h = {})
      return h[:default_page]
  end

  def join_filters(filters=[])
    filters = filters.flatten.reject{|f| f.nil? or f.length==0}
    query_filter = ""
    query_filter = " where " + filters.join(" and ")  if filters.length > 0
    return query_filter
  end

  def get_paginated_list(h = {})
    crosstab_query = self.crosstab_query[:query]
    h[:list_length]||=MadbSettings.list_length
    
    query_filter = join_filters(h [:filters])

    crosstab_count_row =  CrosstabObject.connection.execute("select count(*) from #{crosstab_query} #{query_filter}")[0]
    crosstab_count = crosstab_count_row[0] ? crosstab_count_row[0] : crosstab_count_row['count']
    #determine page to display.If we have a highlight parameter, always display the page of the highlighted item
    paginator = ApplicationController::Paginator.new self, crosstab_count.to_i, h[:list_length], page_number(crosstab_query, h)
    if crosstab_count.to_i>0
      limit, offset = paginator.current.to_sql
      query = "select * from #{crosstab_query}  #{query_filter} order by #{h[:order_by].nil? ? 'id' : CrosstabObject.connection.quote_column_name(h[:order_by].to_s)} #{h[:direction].nil? ? 'ASC' : Entity.connection.quote_string(h[:direction])}"
      if h[:format]!="csv"
        query += " limit #{limit} offset #{offset}"
      end
      CrosstabObject.define_accessors(details_names, serialized_details_names)
#      CrosstabObject.serialize_columns(serialized_details_names)
      list = CrosstabObject.find_by_sql(query)
    else
      list =  []
    end
    return [list , paginator]
  end






end
