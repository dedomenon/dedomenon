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
class Entity < ActiveRecord::Base
  
  has_and_belongs_to_many :details, :join_table => "entities2details"
  #has_and_belongs_to_many :entities, :join_table => "relations", :foreign_key => "parent_id", :association_foreign_key => "child_id"
  has_many :relations_to_children, :class_name => "Relation",  :foreign_key => "parent_id"
  has_many :relations_to_parents, :class_name => "Relation",  :foreign_key => "child_id"
  has_many :entity_details
  has_many :instances, :dependent => :destroy
  belongs_to :database
  
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
    self.details.sort{|a,b| a.display_order<=>b.display_order}.delete_if{|d| d.displayed_in_list_view!='t'}
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
  def details_hash
    @details_hash||=entity_details.collect{|ed| ed.detail}.inject({}){|acc,i| acc.merge( { i.name => i}) }
  end
  #
  # Cleans params to only key values to be assigned to detail_values related to this entity
  def clean_params(h)
     h.reject{|k,v| not details.collect{|d| d.name}.include?(k)}
  end

  # Build params to pass to save_entity
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
          params[detail.name].each do |i,value|
            # if the value id is not provided, that means
            # the underlying DetailValue does not exists and we need to create
            # it. This block assigns the variable detail_value
            if value["id"].nil? or value["id"]==""
                
              # However, if the value is not preset, Sorry! Move next because
              # we do not insert empty values.
              if value["value"]=="" or ( value["value"].respond_to?( :original_filename) and value["value"].original_filename=="")
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
                invalid_list.push "#{form_id}_#{entity.name.gsub(/ /,"_")}_#{detail.name}[#{i}]_value"
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
            
          end if params[detail.name] # end of do block
      
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
  
  #alias to_json old_to_json
       
  #FIXME: Add the options behaviour as a standard behaviour
  #FIXME: When the initial string is null, should proceed next.
#  def to_json(options={})
#    
#    json = JSON.parse(super(options))
#    replace_with_url(json, 'id', :Entity, options)
#    replace_with_url(json, 'database_id', :Database, options)
#    
#    format = ''
#    format = '.' + options[:format] if options[:format]
#    
#    json[:details_url] = @@lookup[:Entity] % [@@base_url, self.id]
#    json[:details_url] += (@@lookup[:Detail] % ['', '']).chop + format
#    
#    json[:instances_url] = @@lookup[:Entity] % [@@base_url, self.id]
#    json[:instances_url] += (@@lookup[:Instance] % ['', '']).chop + format
#    
#    json[:relations_url] = @@lookup[:Entity] % [@@base_url, self.id]
#    json[:relations_url] += (@@lookup[:Relation] % ['', '']).chop + format
#    
#  
#    return json.to_json
#    
##    #json = old_to_json(opts)
##    
##    # remove any whitespace
##    json.strip!
##    
##    # Subtitute the escape sequence chracters
##    json.gsub!(/\\/, '')
##    
##    # Delete the bracket
##    json.delete!('}')
##    
##    # remove the enclosing quote symbols
##    if json.length > 2
##      json = json[1, json.length]
##    end
##    
##    json.chop!
##    
##    base_url = 'http://localhost:3000/'
##    self_url = '"' + base_url + "entities/#{id}" + '"'
##    database_url = '"' + base_url + "databases/#{database_id}" + '"'
##    
##    json.gsub!(/("id":\s+\d+)/, '"url": ' + self_url )
##    json.gsub!(/("database_id":\s+\d+)/, '"database_url": ' + database_url )
##    
##    
##    
##    base_url = 'http://localhost:3000/'
##    str = '"has_file_attachment_detail": '  +  j(has_file_attachment_detail?) + ', ' +
##      '"details_url":'          + '"' + base_url + "entities/#{id}/details.json"   + '"' + ', ' +
##      '"instances_url": '       + '"' + base_url + "entities/#{id}/instances.json" + '"' + ', ' +
##      '"relations_url":'        + '"' + base_url + "entities/#{id}/relations.json" + '"'
##          
##          
##    
##    
##    
##    json = json + ', ' + str + '}'
##    
##    
##    
##    
##    
##    return json;
##    
##       
#  end
end
