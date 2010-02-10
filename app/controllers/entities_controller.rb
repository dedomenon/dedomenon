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
#   This class mostly handles the creation of instances and lists
#   various aspects of an entity like the records in it, the relations it has
#   with other entities etc.
#   @json is available for the data exchange with the REST controllers.
#   If further fomrats are supported like XML and YAML, then there would be
#   additional instance variables called 
class EntitiesController < ApplicationController

  require 'entities_module'
  include EntitiesHelpers
  require "time"
  #model :integer_detail_value
  #model :date_detail_value
  #model :long_text_detail_value
  #model :email_detail_value
  #model :web_url_detail_value
  #model :entity_detail

  # For all actions, the user must be logged in execpt ones listed in the array.
  before_filter :login_required , :except => ["public_form","public_form_javascript", "apply_edit", "check_detail_value_validity"]
  
  # For the listed actions, check whether the pulic access is available to the 
  # rquested entity.
  before_filter :check_public_access, :only => ["public_form", "public_form_javascript","apply_edit"]
  
  # Checks whether the request contains the requried ids or not. But the actions
  # listed in the array below are not checked for this.
  before_filter :check_all_ids, :except => ["public_form", "apply_edit"]
  
  # For the actions of list, view and add, a return url is set.
  before_filter :set_return_url , :only => ["list", "view", "add"]
  
  layout :determine_layout


  # *Description*
  # Not defined yet, Raphael to instruct on that.
  def public_form_javascript
  end
  
  # *Description*
  #   This function checks whether the requested entity has a public access
  #   form or not. If the user is logged in then the @db is also set to the 
  #   database requested by the user. its also checked whether the database
  #   to which this entity belongs belongs to the current user or not.
  #
  def check_public_access
    

    entity=Entity.find entity_id
    @db= entity.database
    return true if user_dbs.include? entity.database


    if !entity.has_public_form?
        render :text => 'Form inactive or not found', :status => 404 and return false;
    end
    if params["action"]=="apply_edit"
      render :text => '', :status => 404 and return false if params[:instance_id]!="-1"
    end
    
  end
  
  # *Description**
  #   This function sets the @db instance varaible when its provided either
  #   the instance id or entity id.
  #
  def check_all_ids
    # id
    # --
    if params["id"]
      # entity.id
      # ---------
      if ["entities_list","list","add"].include? params["action"]
        begin
          @db = Entity.find(params["id"]).database
        rescue ActiveRecord::RecordNotFound
          flash["error"]=t("madb_error_data_not_found")
          redirect_to :controller => "database" and return false
        end
        if ! user_dbs.include? @db
          flash["error"] = t("madb_entity_not_in_your_dbs")
          redirect_to :controller => "database" and return false
        end
      # instance.id
      # -----------
      elsif ["view", "edit", "apply_edit"].include? params["action"]
        begin
          @db = Instance.find(params["id"]).entity.database
        rescue ActiveRecord::RecordNotFound
          flash["error"]=t("madb_error_data_not_found")
          redirect_to :controller => "database" and return false
        end
        if ! user_dbs.include? @db
          flash["error"] = t("madb_instance_not_in_your_dbs")
          redirect_to :controller => "database" and return false
        end
      end
    end
  end



  # *Description*
  #   Most of the logic is inclined towards views.
  def entities_list
    #FIXME: check we get the params id when editing an instance
    @entity = Entity.find params["id"]

    # If the table(entity) contains no record then error
    if Instance.count(:all, :conditions=> ["entity_id=?",params["id"]])==0
      render :text => t("madb_no_instance_found",{:entity => @entity.name}) and return
    end

    @details = @entity.details_hash
    # list id is of the format "entityname_list like prjects_list"
    @list_id = list_id
    
    if !params["detail_filter"].nil?
      # Div class relates to the class of the table generated by the underlying view
      @div_class = "filtered"
      @separator = "and"   #separator used in page_number method
    else
      @div_class = "unfiltered"
      @separator = "where"
    end
    crosstab_result =  @entity.crosstab_query_for_entity(:display=> list_display)



    if crosstab_result.nil?
      render :text => t("madb_entries_found_but_no_details_to_be_displayed_in_list")
      return
    end
    crosstab_query     = crosstab_result[:query]
    @not_in_list_view  = crosstab_result[:not_in_list_view]
    @ordered_fields   = crosstab_result[:ordered_fields]
    
    @list = get_paginated_list(crosstab_query, :filters => [ crosstab_filter ])
    
    response.headers["MYOWNDB_highlight"]=params["highlight"].to_s if params["highlight"]

    if params["format"]=="csv"
      csv_string = render_to_string :template => "entities/entities_list_csv"
      send_data(csv_string,:filename => @entity.name+".csv", :type => 'text/csv; charset=UTF-8')
    end
  end
  


  # *Description*
  #   Shows all the instances of the given entity ID.
  #   
  # REST:
  # GET /entities/:entity_id/instances/
  # GET /databases/:database_id/entities/:entity_id/instances
  
  def index
      entities_list()
  end
  
  # *Description*
  #   Lists the records of the given entity.
  # Calls the EntitiesController#entities_list mehtod beneath the surface
  # from the view.
  def list
    @entity = Entity.find params["id"]
    @title = t("madb_list", :vars => { 'entity' => t(@entity.name, :scope => "account")})
    @list_id = list_id
  end

  # *Description*
  #   Shows a single instance
  #   
  # *REST_API*
  #   GET entities/:entity_id/instances/:id
  #   GET databases/:database_id/entities/:entity_id/instances/:id
  # FIXME: For now, we ignore the entity_id and database_id
  # Make to regard them!!!
  def show()
    view()
  end
  
  # *Description*
  #   This basically shows a particular instance.
  #
  def view
    @instance = Instance.find params["id"]
    @entity = @instance.entity :include => [ :entity_details ]
    @title = t("madb_entity_details", :vars => { 'entity' => t(@entity.name, :scope => "account")})
    @crosstab_object = CrosstabObject.find_by_sql(details_query_for_instance(@instance.id)+" order by display_order")
  end

  def edit
  	@instance = Instance.find params["id"]
	@entity = @instance.entity
  end
  
  

  # *Description*
  #   Populates the form for the given entity
  #
  def init_add_form
    @entity = Entity.find params["id"]
  end

  # *Description*
  #   Initiates the addition form.
  def add
    init_add_form
    @list_id = list_id
    @title = t("madb_add_and_instance", :vars => { 'entity' => @entity.name})
  end

  # *Description*
  # Saves the given instance or creates a new if it does not exsits.
  # 
  # *Workflow*
  #   Follwilng containers are used:
  #      * ret for representing the sucsuss of the operation
  #      * detail_saved to enlist the fields that saved 
  #      * @invalid_list to enlist the fields that are invalid.
  #   The instance_id is picked from the params and if its negative,
  #   it means we need to create an instance other wise, the instance is picked 
  #   from the database.
  #   For all the fields of the entity to which instance belongs, the params
  #   values are read from params[field_name] 2d array which is array of the
  #   form:
  #     FieldName[number][id|value]
  #   Like if you have a field containing the age then you would have following
  #   setup:
  #     Age[0][value]     # for record 0
  #     Age[1][value]     # for record 1
  #
  #   If the instance is to be created instead of edited, the id fields of the
  #   2d Arry would be empty:
  #   Age[0][id] = ""
  #   Age[0][id] = ""
  #   
  #   But if the instance is to be edited, the id column holds the id of the
  #   Detail value.
  #   
  #   For each of the detail, if the id is not present, then we need to create
  #   the value by pick the datatype of the detail and create a detail_value
  #   object out of it.
  #   But if the id is present then that detail value is picked.
  #   Next step is simply copying the value recieved from the client
  #   to the detail value object and saving it.
  #   See the source code for complete details.
  #
#  def save_entity
#    id = params["instance_id"].to_i
#    ret = true
#    detail_saved = false
#    @invalid_list = []
#    detail_values = [] # used to keep all detail_value that we saved, and call destroy on s3 attachments if needed
#    
#    begin
#      Entity.transaction do
#        entity = Entity.find params["entity"]
#      # Negative IDs are used for creating the instances
#      if id>0
#        @instance = Instance.find(id)
#      else
#        @instance = Instance.new
#        @instance.entity=entity
#        @instance.save
#       end
#	
#        # We pick all the details of the entity
#        #FIXME: This code uses EntityDetail class
#        @instance.entity.entity_details.each  do |entity_detail|
#          
#          detail = entity_detail.detail
#          params[detail.name].each do |i,value|
#            # if the value id is not provided, that means
#            # the underlying DetailValue does not exists and we need to create
#            # it.
#            if value["id"].nil? or value["id"]==""
#                
#              # However, if the value is not preset, Sorry! Move next because
#              # we do not insert empty values.
#              if value["value"]=="" or ( value["value"].respond_to?( :original_filename) and value["value"].original_filename=="")
#                next
#              end
#              
#              # Crucial!
#              # * Get the class from the datatype.
#              # * Create an instance of that dataype
#              # * Set the value
#              # * Connect to the instance
#              detail_value_class = class_from_name(detail.data_type.class_name)
#              detail_value = detail_value_class.new
#              
#              # This generates error! AssociationTypeMismatch by detail=
#              #detail_value.detail = detail # Detail.find(:all, "name='#{detail.name}'")[0]
#              
#              # Therefore, this is the hack around!
#              detail_value.detail_id = detail['id']
#              detail_value.instance_id = @instance['id']
#              # Otherwise, if the id is present, we need to updat that!
#            else
#              
#              # We pick the class for the detail.
#              detail_value_class = class_from_name(detail.data_type.class_name)
#		
#              # if the value is left blank, we would be deleting the detail
#              # of that ID.
#              if value["value"]==""
#                detail_value_class.delete(value["id"])
#                next
#              end
#              # Pick the detail value of that class by the ID given
#              detail_value= detail_value_class.find(value["id"])
#            end
#	
#            begin
#              # If the provided value is not valid, then the return value would
#              # be false and we push the detail in the @invalid_list
#              if ! detail_value_class.valid? value["value"], {:session => session, :entity => entity}
#                ret = false
#                @invalid_list.push "#{params["form_id"]}_#{entity.name.gsub(/ /,"_")}_#{detail.name}[#{i}]_value"
#              end
#            rescue Exception => e
#            end
#	
#            # If we had any invalide field, we simply do not
#            # save.
#            next if @invalid_list.length>0
#            
#            # Crucial!
#            # * Pick the field value
#            # * Save it
#            # * Yes, the detail saved!
#            # * Save it in the list of saved detail values
#            detail_value.value=value["value"]
#            detail_value.save
#            detail_saved = true
#            detail_values.push detail_value
#            
#          end if params[detail.name] # end of do block
#      
#        end
#
#        #raise exception to rollback if necessary
#	raise "invalid form" if !ret
#	raise "no detail saved" if !detail_saved
#		
#      end
#
#    # If any trouble, we do a bit of cleanup!
#    rescue Exception => e
#      #breakpoint "exception"
#      #flash["error"] = t("madb_error_creating_instance")
#      if e.message=="invalid form"
#        detail_values.each do |dv|
#          dv.destroy if dv.detail.data_type.name == "madb_s3_attachment"
#        end
#      end
#      raise e #if RAILS_ENV=="production"
#		end
#    return ret
#  end

  # *Description*
  #   Applys the editing changes.
  #   internally calss the EntitiesController#save_entity
  def apply_edit
    entity_saved=false
    # Try to save the entity
    begin
      entity_saved, @invalid_list= Entity.save_entity(params)
      
    rescue RuntimeError => e
      if e.message == "no detail saved"
        render :text => "__ERROR__"+t("madb_no_detail_saved_enter_at_least_one_valid_value")
        return
        #we should raise other exceptions
      end

    end


    if entity_saved #sets @instance
      @instance = entity_saved
      
      # if saved and we have auser of this database, list entites otherwise nothing
      if session["user"] and user_dbs.include? @db
        render_component  :controller => "entities", :action => "entities_list", :id => params["entity"], :params =>{ :highlight => @instance.id }
      else
        render :nothing => true and return;
      end
                       
    else
			#if request.xhr?
      # Otherwise if not saved, we simply list the fields that are 
      # invalid.
      headers['Content-Type']='text/html; charset=UTF-8'
      render :text => @invalid_list.join('######')
      return

    end
  end

  # *Description*
  #   Unlinks two instances.
  #   
  # *REST_API*
  #   DELETE /entities/:entity_id/instances/:id 
  #   DELETE databases/:database_id/entities/:entity_id/instances/:id 
  #   
  #  REST API params:
  #   parent_id is the parnet participent of the relation
  #   child_id is the child participant of the relation
  #   and either of these should be provided.
  #   relation_id is the id of the type of the relation with which the two
  #   instances are linked.
      
  def unlink
    
    if params["parent_id"]
      parent_id = "parent_id"
      child_id = "id"
      render_id = "parent_id"
      type = "children"
    else
      parent_id="id"
      child_id = "child_id"
      render_id = "child_id"
      type = "parents"
    end
  	Link.delete_all("parent_id=#{params[parent_id]} AND child_id=#{params[child_id]} AND relation_id=#{params["relation_id"]}")
    #overwrite_params doesn't work with render_component
      render_component(:controller => "entities", :action => "related_entities_list", :id => params[render_id],:params => { :relation_id => params["relation_id"] , :type => type }) 
  end

  # *Description*
  # This function lists all the available entities which can be linked to 
  # the given entity.
  def list_available_for_link
  	@relation = Relation.find params["relation_id"]
    if params["parent_id"]
      @list_id = "#{@relation.from_parent_to_child_name}_linkable_list"
      #links_div contains the links to link a new/existing child
      @links_div = "#{@relation.from_parent_to_child_name}_child_div_add_child_links"
      related_id = "child_id"
      self_id = "parent_id"
      @entity = @relation.child
      #if parent_side_type is one, we filter out all entities already link at the one side
      #if parent_side_type is many, we filter out all entities already link to this entity
      if @relation.parent_side_type.name!="one"
        @link_to_many = 't'
        other_side_type_filter= " and #{CrosstabObject.connection.quote_string(self_id)}=#{CrosstabObject.connection.quote_string(params[self_id].to_s)}"
      end
    else
      @list_id = "#{@relation.from_child_to_parent_name}_linkable_list"
      #links_div contains the links to link a new/existing parent
      @links_div ="#{@relation.from_child_to_parent_name}_parent_div_add_parent_links"
      related_id = "parent_id"
      self_id = "child_id"
      @entity = @relation.parent
      #if child_side_type is one, we filter out all entities already linked at the one side
      #if child_side_type is many, we filter out only entities already linked to this entity
      if @relation.child_side_type.name!="one"
        @link_to_many = 't'
        other_side_type_filter= " and #{self_id}=#{CrosstabObject.connection.quote_string(params[self_id].to_s)}"
      end
    end

    @details = @entity.details_hash
    filter_clause = crosstab_filter
    link_filter = "id not in (select #{related_id} from links where relation_id = #{@relation.id} #{other_side_type_filter})"

    order=order_by
    crosstab_result = @entity.crosstab_query_for_entity(:display => "detail")
    crosstab_query     = crosstab_result[:query]
    @not_in_list_view  = crosstab_result[:not_in_list_view]
    @ordered_fields   = crosstab_result[:ordered_fields]
    @list = get_paginated_list(crosstab_query, :filters => [ filter_clause , link_filter ] )



    @links = [ { "header" => "Use it" , "text" => "Use it", "options" => {:action => "link", self_id.to_sym => params[self_id], :relation_id => params["relation_id"]}, "evals" => ["id"]  },
				   ]
  end




  def link_to_existing
  	@relation = Relation.find params["relation_id"]
    if params["parent_id"]
      @list_id = "#{@relation.from_parent_to_child_name}_linkable_list"
      @related_id = "child_id"
      @self_id = "parent_id"
      @entity = @relation.child
    else
      @list_id = "#{@relation.from_child_to_parent_name}_linkable_list"
      @related_id = "parent_id"
      @self_id = "child_id"
      @entity = @relation.parent
    end
		#FIXME: check this is ok if we have a relation to the same entity. It will then appear in children and parents related entities.
  end

  def link_to_new
  	init_add_form
	if params["parent_id"] 
		linked_id = "parent_"+params["parent_id"]
	elsif params["child_id"] 
		linked_id = "child_"+params["child_id"]
	end
    	@relation = Relation.find params['relation_id']
	@form_id = @relation.id.to_s+"_"+@entity.id.to_s+"_"+linked_id
  end

  def apply_link_to_new
    entity_saved=false
    begin
      entity_saved, @invalid_list = Entity.save_entity(params)
      @instance = entity_saved
    rescue RuntimeError => e
      if e.message == "no detail saved"
        render :text => "__ERROR__"+t("madb_no_detail_saved_enter_at_least_one_valid_value")
        return
      end
    end
    if entity_saved
      if params["parent_id"]
              child = @instance
              parent = Instance.find params["parent_id"]
      elsif params["child_id"]
          parent = @instance
          child = Instance.find params["child_id"]
      else
          raise "Missing parameter parent_id (#{params["parent_id"]}) or child_id (#{params["child_id"]})"
      end
      relation = Relation.find params["relation_id"]
      link_entities(parent,relation,child)
      headers['Content-Type']='text/plain; charset=UTF-8'
    else
    #	if request.xhr?
            headers['Content-Type']='text/plain; charset=UTF-8'
            render :text => @invalid_list.join('######')
            return
    #	else
                #redirect_to_url session['return-to']
                #redirect_to :action => "list", :id => @instance.entity
    #	end
    end
  end

  def link_entities(parent,relation,child)
	begin
    if relation.parent_side_type.name=="one"
      #parent side is one, so if child is already linked to one, cannot be linked again.....
      if Link.count(:conditions => "child_id=#{parent.id} and relation_id=#{relation.id}")>0
        raise "madb_not_respecting_to_one_relation"
      end
    end
    if relation.child_side_type.name=="one"
      if Link.count(:conditions => "parent_id=#{parent.id} and relation_id=#{relation.id}")>0
        raise "madb_not_respecting_to_one_relation"
      end
    end
		link = Link.new
		link.child = child
		link.parent = parent
		link.relation = relation
		link.save


	rescue ActiveRecord::StatementInvalid=> @e
		existing_links = Link.find(:all, :conditions => [ "relation_id=? AND parent_id=? AND child_id=?", params["relation_id"],params["parent_id"],params["id"]])
		if existing_links.length>0
			flash["error"]  = t("madb_error_record_already_linked")
		else
			flash["error"] = t "madb_an_error_occured"
		end
	rescue RuntimeError => @e
    if @e.message=="madb_not_respecting_to_one_relation"
      flash["error"] = t("madb_not_respecting_to_one_relation")
    end

	rescue Exception => @e
      flash["error"] = t("madb_an_error_occured")
  ensure
      if params["parent_id"]
        if params["embedded"]
           redirect_to :controller => "entities", :action => "related_entities_list", :id => params["parent_id"],  :relation_id => relation.id, :type => "children", :highlight => child.id 
        else
          redirect_to(:action => "view", :id=>parent.id) 
        end
      elsif params["child_id"]
        if params["embedded"]
           redirect_to :controller => "entities", :action => "related_entities_list", :id => params["child_id"],  :relation_id => relation.id, :type => "parents", :highlight => parent.id 
        else
           redirect_to(:action => "view", :id=>child.id) 
        end
    end
    #if params["parent_id"]
    #  redirect_to(:action => "view", :id=>parent.id)
    #elsif params["child_id"]
    #  redirect_to(:action => "view", :id=>child.id)
    #end
	end
  end

  # *Description*
  # Links the two instances
  # 
  # *REST_API*
  #   id of the instance is to be provided in params[:id] and
  #   params[:parent_id] | params[:child_id] along with the relation_id
  #
  def link
  if params["child_id"]
    child_id = "child_id"
    parent_id = "id"
  else
    parent_id = "parent_id"
    child_id = "id"
  end

	relation = Relation.find params["relation_id"]
	parent = Instance.find params[parent_id]
	child = Instance.find params[child_id]
  
	link_entities(parent,relation,child)
  end


  # *Description*
  #   Lists the related entities.
  #
  # REST Parameters:
  #   reltaion_id
  #   type
  #
  def related_entities_list

    @relation = Relation.find params["relation_id"]
    @type = params["type"]
    @details = {}
    #this is changed later in the code if necessary
    @link_to_many = 'f'

    # if the type is childeren, we are connecting parent to childeren
    # otherwise the other way around.
    if @type == "children"
      type = {:from => "parent", :to => "child"}
    else
      type = {:from => "child", :to => "parent"}
    end

      @link_type = type[:to]
      @relation_name = @relation.send("from_#{type[:from]}_to_#{type[:to]}_name")
      @list_id = "#{@relation_name}_#{type[:to]}"
      @links_div ="#{@relation_name}_#{type[:to]}_div_add_#{type[:to]}_links"
      @add_new_link ="#{@relation_name}_#{type[:to]}_div_add_new_#{type[:to]}_link"
      @add_existing_link ="#{@relation_name}_#{type[:to]}_div_add_existing_#{type[:to]}_link"
      @source_id = "#{type[:from]}_id"
      linked_entity = @relation.send(type[:to]).name
      linked_entity_object = @relation.send(type[:to])
      @instance = Instance.find params["id"]
      if @relation.send("#{type[:to]}_side_type").name!="one"
        @link_to_many = 't'
      end


    EntityDetail.find( :all,:conditions =>  ["entity_id=?", linked_entity_object.id]).each do |d|
      @details[d.detail.name.downcase]=d.detail
    end




    #FIXME : the first version of list_id could be used somewhere else
    #@list_id = "#{@instance.entity.name}_#{linked_entity}_list"
    order = order_by

    if !params["detail_filter"].nil?
      @div_class = "filtered"
    else
      @div_class = "unfiltered"
    end
    clause = crosstab_filter

    # THIS GENERATES LOTS OF QUERIES LIKE  SELECT * FROM instances WHERE instances.id = 139 LIMIT 1
    if @type=="children"
    #  @list= @instance.links_to_children.delete_if(&filter).collect{|e| e.child}
      ids_to_keep = @instance.links_to_children.reject{ |l| l.relation!=@relation }.collect { |l| l.send("#{@link_type}_id")  }.uniq.join(",")
    elsif @type=="parents"
    #  @list= @instance.links_to_parents.delete_if(&filter).collect{|e| e.parent}
      ids_to_keep = @instance.links_to_parents.reject{ |l| l.relation!=@relation }.collect { |l| l.send("#{@link_type}_id")  }.uniq.join(",")
    end


    filters =  ["id in (#{ids_to_keep})",  clause]
    crosstab_result = linked_entity_object.crosstab_query_for_entity()
    if crosstab_result
      crosstab_query     = crosstab_result[:query]
      @not_in_list_view  = crosstab_result[:not_in_list_view]
      @ordered_fields   = crosstab_result[:ordered_fields]
    else
      crosstab_count = 0
      linked_count=0
    end

    if ids_to_keep.length>0
      count_row =  CrosstabObject.connection.execute("select count(*) from #{crosstab_query} #{join_filters(filters)}")[0]
      crosstab_count = count_row[0] ? count_row[0] : count_row['count']
      #use linked_count result to determine links display (to associate other entries)
      linked_row =  CrosstabObject.connection.execute("select count(*) from #{crosstab_query}  where id in (#{ids_to_keep}) ")[0]
      linked_count = linked_row[0] ? linked_row[0] : linked_row['count']
    else
      crosstab_count =0
    end
    if crosstab_count.to_i > 0
      page_number = page_number(crosstab_query)
      if params["highlight"]
        response.headers["MYOWNDB_highlight"]  =  params["highlight"].to_s
      end

      @list = get_paginated_list(crosstab_query, :filters =>  filters  )
    else
      @list = []
    end

    @hide_to_new_link = false;
    @hide_to_existing_link = false;
    #to one relation with linked instance
    if @link_to_many!='t' and linked_count.to_i > 0
      @hide_to_new_link = true;
      @hide_to_existing_link = true;
    end
    #to many relation
    if @link_to_many=='t'
      #check if instances available for linking
        link_to_many = @relation.send("#{type[:to]}_side_type").name=='many'
        link_from_many = @relation.send("#{type[:from]}_side_type").name=='many'
        if link_from_many
          available_instances = Instance.find(:all, :conditions => "entity_id=#{@relation.send(type[:to]).id} and id not in (select #{type[:to]}_id from links where relation_id = #{@relation.id} and #{type[:from]}_id=#{@instance.id})")
        else
          available_instances = Instance.find(:all, :conditions => "entity_id=#{@relation.send(type[:to]).id} and id not in (select #{type[:to]}_id from links where relation_id = #{@relation.id})")
        end
        if available_instances.length<1
          @hide_to_existing_link = true;
        end
    end

    if params["format"]=="csv"
      csv_string = get_csv( { "instances" => @list })
      headers["content_type"]= "text/x-csv"
      send_data(csv_string,:filename => "export.csv")
    end

  end


  def get_csv(data)
    detail_ids = []
    data["entity"] = data["instances"][0].entity if data["instances"].length>0
    s= ""
    data["entity"].details.each  do |detail|
      if detail.displayed_in_list_view=='t'
        detail_ids.push detail.id
        s+=%Q{"#{t(detail.name)}",}
      end
    end
    s.chop
    s.chop
    s+="\n"
   data["instances"].each do |instance|
     data["entity"].details.each do |detail|
       val = class_from_name(detail.data_type.class_name).find(:all, :conditions =>["instance_id=? and detail_id=?",instance.id, detail.id])[
0]
       if detail.displayed_in_list_view=='t'
        if val
          s+=%Q{"#{val.value}",}
        else
          s+=%Q{"",}
        end
       end
     end
     s.chop
     s.chop
     s+="\n"
   end
  return s
  end

  # *Description*
  #   The output from the actions of this contorller can be presented in variuos
  #   forms. It might be embded like through an AJAX request, or it might be
  #   presented in a separate popup window, or it can be in the main application
  #   window. This function determines the layout or presentation of the content
  #   based on the requested actions and type of request.
  #
  def determine_layout
      #no layout if
      # -action=related_entities_list and not popup
      # -action=list_availaible_for_link or entities_list
      # -xhr request
      # -embedded!=nil
      # -displayed as component (=> embedded == true)
		# removed or (["list_available_for_link", "entities_list"].include? params["action"])
    if ( %w(entities_list list_available_for_link related_entities_list public_form_javascript).include? params["action"] and params["popup"].nil?)  or (request.xml_http_request?) or (! params["embedded"].nil?) or (embedded?)
      return nil
      # Otherwise, if the params[:popup] is true and the request is not an
      # AJAX requst then the layout is popup otherwise application.
    elsif params["popup"]=='t' and (!request.xml_http_request?)
      return "popup"
    else
      return "application"
    end
  end

  def delete
    entity=Instance.find( params["id"] ).entity
    begin
      Instance.destroy(params["id"])
    rescue Exception => e
      flash["error"] = t("madb_error_occured_when_deleting_entity")
      logger.error "ERROR : in entities_controller, line #{__LINE__} :   #{e}"
    end
    redirect_to :overwrite_params => { :action => "entities_list", :id => entity.id , :highlight => nil }
  end


  # *Description*
  #  Deletes an instance
  # DELETE entities/:entity_id/instances/:id
  # DELETE /databases/:database_id/instances/:id
  
  def destroy()
      begin
        Instance.destroy(params[:id])
      rescue Exception => e
        flash["error"] = t("madb_error_occured_when_deleting_entity")
        logger.error "ERROR : in entities_controller, line #{__LINE__} :   #{e}"
        return e
      end
      return nil
  end
  
  def check_detail_value_validity
                if request.env["REQUEST_METHOD"]=="OPTIONS"
                  headers["Access-Control-Allow-Origin"]="*"
                  headers["Access-Control-Allow-Methods"] = "*"
                  headers["Access-Control-Allow-Headers"] = "x-requested-with"
                  render :nothing => true
                  return
                end
		#called by javascript form observer
		detail = Detail.find params["detail_id"]
		value = params["detail_value"]
		detail_value_class = class_from_name(detail.data_type.class_name)
                headers["Access-Control-Allow-Origin"]="*"
		if detail_value_class.valid?(value, :session => session)
			render :text => '1'
		else
			render :text => '0'
		end
	end


  def public_form
      @entity = Entity.find params["id"]
      @verification_string = String.random
      @verification_hash = Digest::SHA1.digest(@verification_string)
      session["public_form_check"] =@verification_string
      if params['embedded']=='t' or params[:format]=='js'
        render :layout => false
      else
        render :layout => "public"
      end
  end

  private
  def entity_id
    # if the intended action is public_form or public_form_javascript then
    # the params[:id] is an entitiy id.
    if params["action"]=="public_form" or params["action"]=="public_form_javascript"
      entity_id = params["id"]
    end
    
    # if the intended action is apply_edit then the params[:entity] contains the
    # entity id.
    # reject request if instance_id is not -1, ie if it is for an update 
    if params["action"]=="apply_edit"
      entity_id = params["entity"]
    end
    return entity_id
  end


end
