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
#   This class manages the entities in databases. Entities are like tables
#   in the RDBMS world. See Entity class for details.
#   The services provided by this class usually administer the entities.
#   
#   Allows you to view the entities of a database
#      * index
#      * list
#      * show
#      
#   Allows you to create, edit, update and delete an entity
#     * new     (populates the form for the user)
#     * create  (actually creates an entity)
#     * edit    (popullates a form for an entity editing)
#     * update  (actually udpates an entity)
#     * destroy
#     
#   Allows you to add an existing column(detail) to an entity
#     * add_existing_choose     (populates the form of possible existing fields)
#     * add_existing_precisions (populates a form for detail precision details)
#     * add_existing            (adds an existing detail)
#     * edit_existing_precision (provides form for making changes)
#     * update_existing_precision (actually updates the entity)
#     * unlik_detail            (Unlinks a detail from an entity)
#     
#   Allows you to add, delete and modify the links with other entities.
#     * define_link       (provides a form for defining the link)
#     * add_link          (actually modified a link or creates a new)
#     * edit_link         (picks the details of a relation and shows defin_link)
#                         
#      
#     
#
require 'entities2detail'
class Admin::EntitiesController < ApplicationController
  #NOT NEEDED ALREADY ADDED IN ENVIRONMENT.RB
  #include MadbClassFromName
  before_filter :login_required
  before_filter :check_user_rights  
  before_filter :check_all_ids
  before_filter :set_return_url , :only => ["list", "show","index"]
  
  #model :entities2detail
  
  verify :method => "post", :only => "update_existing_precisions"
  
  # *Description*
  #   Checks whether the current user is admin or not?
  def check_user_rights
    if !session["user"].admin_user?
        flash["error"]=t("madb_you_dont_have_sufficient_credentials_for_action")
        redirect_to :controller => "/database" and return false
    end
  end
  
  # *Description*
  #   
  # *Workflow*
  #   The soul purpose of this method is to set the @db instance variable
  #   when provided with any of the following IDs:
  #     * parent_id 
  #     * child_id
  #     * detail_id
  #     * db (database id)
  #     * detail_id
  #     
  #  If the id param is present and the :action is either
  #  delete_link or edit_link, then the provided id is a relation id
  #  and the database is looked from the reltaions table indirectly.
  #    
  #  FIXME: if the @db is nil, then the view admin/entities/list simply
  #  fails. It happens when a new account is created and it has no
  #  database.    
  #
  def check_all_ids

    if params[:id]
      # If the entity id or the database id are provided, chances are that its
      # a rest calll
      if params[:entity_id] or params[:database_id]
        # If the unlink_detail is the action, we need to arrange the params 
        # So that its directly digestable for the method.
        # This would only occur if:
        # DELETE /entities/:entity_id/details/:id/unlink_detail
        # DELETE /databases/:database_id/entities/:entity_id/details/:id/unlink_detail
        if %w{unlink_detail}.include?(params[:action]) and params[:entity_id]
          
          if any_record?(:Database => params[:database_id],
                      :Entity => params[:entity_id],
                      :Detail => params[:id])
                    
            params[:detail_id] = params[:id]
            params[:id] = params[:entity_id]          
          else
            return false;
          end
          
        end
        
        # If we are going to add an existing detail through the REST API, then
        # it might have following forms:
        # POST entities/:entity_id/details/:id/add_existing
        # POST databases/:database_id/entities/:entity_id/details/:id/add_existing
        if %w{add_existing}.include?(params[:action]) and params[:entity_id]
          if any_record?(:Database => params[:database_id],
                      :Entity => params[:entity_id],
                      :Detail => params[:id])
                    
            # Lets make it digestable for the add_existing method
            params[:detail_id] = params[:id]
            params[:id] = params[:entity_id]
          else
            return false;
          end
        end
      end
    end
    
    if params["id"]
      # if this passes, then the id would be a relation id
      if %w{edit_link delete_link}.include?params["action"]   
        begin
          @db = Relation.find(params["id"]).parent.database
        rescue ActiveRecord::RecordNotFound
          flash["error"]= t("madb_error_incorrect_data")
          redirect_to :controller => "databases" and return false
        end
      else
        begin
          @db = Entity.find(params["id"]).database
        rescue ActiveRecord::RecordNotFound
          flash["error"]=t("madb_error_incorrect_data")
          redirect_to :controller => "databases" and return false
          
        end
      end
      if ! user_admin_dbs.include? @db
        flash["error"] = "entity_not_in_your_admin_dbs"
        redirect_to :controller => "databases" and return false
        
      end
           
    end
    if params["parent_id"]
      begin
        @db = Entity.find(params["parent_id"]).database
      rescue ActiveRecord::RecordNotFound
        flash["error"]=t("madb_error_incorrect_data")
        redirect_to :controller => "databases" and return false
        
      end
      if ! user_admin_dbs.include? @db
        flash["error"] = "entity_not_in_your_admin_dbs"
        redirect_to :controller => "databases" and return false
        
      end
    end
    if params["child_id"]
      begin
        @db = Entity.find(params["child_id"]).database
      rescue ActiveRecord::RecordNotFound
        flash["error"]=t("madb_error_incorrect_data")
        redirect_to :controller => "databases" and return false
        
      end
      if ! user_admin_dbs.include? @db
        flash["error"] = "entity_not_in_your_admin_dbs"
        redirect_to :controller => "databases" and return false
        
      end
    end
      
    # The params[:db] is the databse id being passed before REST.
    # The params[database_id] is what SHOULD BE provided in case of 
    # entitiy being a nested resource of databases like this:
    #  GET databases/6/entities.json.
    # params[databasis_id] is whats BEING PASSED BY RAILS!
    # If the database_id is 0, this means that we want the list of
    # all the entiteis. The same is adopted for other nested resources.
    # FIXME: It would be eliminated.
    @db_id = 0
    if params[:db] or params[:database_id] or params[:databasis_id]
      @db_id = params[:db] || params[:database_id] || params[:databasis_id]
      @db_id = @db_id.to_i
        
      begin
        @db= Database.find(@db_id)
      rescue
        flash["error"] = t("madb_requested_db_not_found")
        redirect_to :db => user_admin_dbs[0] and return false
      end
      if ! user_admin_dbs.include? @db
        flash["error"] = t("madb_requested_db_not_in_your_admin_dbs")
        redirect_to :controller => "databases" and return false
      end
    end
    
    if params["detail_id"]
      begin
        @db = Detail.find(params["detail_id"]).database
        if params["db"] and @db.id.to_i!=params["db"].to_i
          flash["error"]=t("madb_error_incorrect_data")
          redirect_to :controller=> "databases" and return false
        end
      rescue ActiveRecord::RecordNotFound
        flash["error"]=t("madb_error_incorrect_data")
        redirect_to :controller => "databases" and return false
      end
      if ! user_admin_dbs.include? @db
        flash["error"] = "detail_not_in_your_admin_db"
        redirect_to :controller => "databases" and return false
      end
    end
  end
  
  def any_record?(items = {})
    
    items.each_pair do |model, id|
      next if id == nil
      if !class_from_name(model.to_s).exists?(id.to_i)
        return false; 
      end
    end
    
    return true;
    
  end
  # This method is supposed to do the folllowing:
  # It would check whether the record exists or not
  
  def handle_rest_call
  
    if params[:db]
      return false;
    end
    
    # If its this:
    # entities/:id
    if %w{show update destroy list_details}.include?(params[:action]) and params[:id]
      return any_record?(:Entity => params[:id])
    end
    
    # If its this:
    # databases/:database_id/entities/:id
    if %w{show update destroy list_details}.include?(params[:action]) and params[:database_id] and params[:id]
      return any_record?( :Database => params[:database_id],
                          :Entity => params[:id])
    end
    
    #If its like these:
    # entities/
    if %w{index create}.include?(params[:action])
      return true;
    end
    
    # If its like this:
    # databases/database_id/entities
    if %w{index create}.include?(params[:action]) and params[:database_id]
      return true;
    end
    
    # entities/:entity_id/details/:id
    # unlink_detail, link_detail
    if %w{unlink_detail add_existing}.include?(params[:action]) and (params[:entity_id] and params[:id])
      # The methods unlink_detail and add_exsiting expect the following:
      # id to be entity id
      # deatil_id to be the id of the detail.
      # 
      # But with the REST API URLs, we get it this way:
      # entities/:entity_id/details/:id
      # databases/:database_id/entities/:entity_id/details/:id/[add_existing|unlink_detail]
      # 
      # Insteand of changing the code and breaking the existing views, we 
      # simply swap this values the way which suites for these methods.
      #
      # The id is basically a detail_id
      params[:detail_id] = params[:id]
      # And the entity_id is the id!
      params[:id] = params[:entity_id]
      return true;
    end
    
    # If its like this:
    # databases/:database_id/entities/:entity_id/details/:id
    if %w{unlink_detail add_existing}.include?(params[:action]) and (params[:database_id] and params[:entity_id] and params[:id])
      # Same as before!
      params[:detail_id] = params[:id]
      params[:id] = params[:entity_id]
      return true;
    end
    
    # If its like this:
    # POST entities/:entity_id/relations/:id
    if %w{add_link}.include?(params[:action]) and (params[:entity_id] and params[:id] and params[:relation])
      params[:relation_id] = params[:id]
      return true;
    end
    
    # if its like this:
    # entities/:entity_id/relations
    # We do not bother for the longer version for now:
    # databases/:database_id/entities/:entity-id/relations/:id
    if %w{add_link}.include?(params[:action]) and (params[:entity_id] and params[:relation])
      return true;
    end
    
    # If its like this:
    # DELETE entities/:entity_id/relations/:id
    if %w{delete_link}.include?(params[:action]) and (params[:entity_id] and params[:id])
      # This is because the method expects source_id to be the id of the source
      # Entity. And our REST call already contains it.
      params[:source_id] = params[:entity_id]
      return true;
    end
    # In all other cases, its not a REST CALL
    return false;
    
    
    
    
  end
  # *Description*
  #   Shows the entities of a database
  #   
  # *REST API*
  #   Call:   GetEntitiesOfDB(db)
  #     Method: GET
  #     Args:
  #       db:         ID of the database.
  # 
  # GET /databases/databasis_id/entities.format
  #
  def index
    list
    render :action => 'list' if params[:controller] == 'admin/entities'
  end

  # *Description*
  #   Lists all the entities(tables) of a database
  # *REST API*
  #   Call:   GetEntitiesOfDB(db)
  #     Method: GETw
  #     Args:
  #       db:         ID of the database.
  # 
  #
  def list
    
    params[:database_id] = params[:database_id] || params[:database] || params[:db]
    if params[:database_id]
      @entities = Entity.find(:all, :conditions => ["database_id =?",params[:database_id]] , :offset => params['start-index'], :limit => params['max-results'], :order => "id")
    else
      @entities = Entity.find(:all, :offset => params['start-index'], :limit => params['max-results'])
    end
    
  end

  # *Description*
  # Shows a particular entity
  # Along with its details and relationships.
  # 
  # *REST API*
  #   Call:   ShowEntity(Entity)
  #     Method: GET
  #     Args:
  #       id:         ID of the entity
  # 
  # REST API Decision:
  #    This does not returns the relations to parents and relations to
  #    childs as this was meant for the views. This stuff would be handled
  #    in the Relations controller which yet does not exists.
  #   
  def show
    
      # If the parent resource is not provided, then dont care pick anything
      # 
    if params[:database_id]
      @entity = Database.find(params[:database_id]).entities.find(params[:id])
    else
      @entity = Entity.find(params[:id])
    end
      
#      if @db_id == 0
#        @entity = Entity.find params[:id]
#      else
#        # Otherwise... we are strict!
#        @entity = Entity.find(:conditions => ["id = ? AND database_id =?", params[:id], @db_id])
#      end

    # Only execute this block if its a call for the admin/entities
    # This is because this code is about the views.
    if params[:controller] == 'admin/entities'
      @relations_to_parents = @entity.relations_to_parents
      @relations_to_children = @entity.relations_to_children
      details_to_add = @db.details - @entity.entity_details.collect{|ed| ed.detail}
      @existing_details_available = details_to_add.length>0
      @title = t("madb_admin_entity", :vars=> { 'entity'=> @entity.name} ) 
    end
  end

  # *Description*
  #   Creates a new entity.
  ## *REST API*
  #   Call:   CreateNewEntity(DatabaseID)
  #     Method: GET
  #     Args:
  #       db:         ID of the database.
  # 
  #
  def new
    @entity = Entity.new
  end

  # *Description*
  #   Saves the entity to the data store.
  # *REST API*
  #   Call:   CreateEntity
  #     Method: POST
  #     Args:
  #       db:         ID of the database.
  #       entity:
  #         name:     Name of the database
  # 
  #
  def create
    
      @entity = Entity.new(params[:entity])
      
#      if @db_id > 0
#        db = Database.find @db_id
#      else
#        format.html
#        format.json { render :json => 'Bad Request', :status => 400 }
#        format.xml { render :xml => 'Bad Request', :status => 400 }
#      end

    # If its being called as a nested resource
    if params[:database_id]
      db = Database.find(params[:database_id])
    else
      # Or if its being called as standalone resource then you are expected 
      # to provide database id of the entity in the params[:entity] or it 
      # should be in the hidden input field with the name of db
      #
      if params[:entity][:database_id]
        db = Database.find(params[:entity][:database_id])
      else
        # Otherwise the call is coming from the views in the hidden 
        # input field in views/admin/entities/_form.rhtml
        db = Database.find(params[:db])
      end
    end

    @entity.database = db
    if @entity.save
      flash['notice'] = 'Entity was successfully created.'
      redirect_to :action => 'list', :db => db if params[:controller] == 'admin/entities'
      @msg = 'OK'
      @code = 201  
    else
      render :action => 'new' if params[:controller] == 'admin/entities'
      @msg = 'Bad Request (Faild to save the entity)'
      @code = 400
    end
  end

  # *Description*
  #   Allows the editing of an entity.
  #   
  # *REST API*
  #   Call:   EditEntity
  #     Method: POST
  #     Args:
  #       id:         ID of the entity
  # 
  #
  def edit
    @entity = Entity.find(params[:id])
  end

  # *Description*
  #   Updates an entity.
  #
  # *REST API*
  #   Call:   UpdateEntity
  #     Method: POST
  #     Args:
  #       id:         Id of the entity
  #       entity:
  #         name:     name of the entity
  #       
  # 
  #
  def update
#    if @db_id == 0
#      @entity = Entity.find(params[:id])
#    else
#      #@entity = Entity.find(:conditions => ["id = #{params[:id]} and database_id = #{@db_id}"])
#      @entity = Entity.find(:first, :conditions => {:id => params[:id], :database_id => @db_id})
#    end

    if params[:database_id]
      @entity = Database.find(params[:database_id]).entities.find(params[:id])
    else
      @entity = Entity.find(params[:id])
    end
    
    
      if @entity.update_attributes(params[:entity])
        flash['notice'] = 'Entity was successfully updated.'
        redirect_to :action => 'show', :id => @entity if params[:controller] == 'admin/entities'
        @msg = 'OK'
        @code = 200
      else
        render :action => 'edit' if params[:controller] == 'admin/entities'
        @msg = 'Bad Request (Faild to save entity)'
        @code = 400
      end
    
  end

  # *Description*
  #   Deletes an entity.
  #
  ## *REST API*
  #   Call:   DestroyEntity
  #     Method: POST
  #     Args:
  #       id:         ID of the entity
  # 
  #
  def destroy
#    if @db_id == 0    
#      entity = Entity.find(params[:id])
#    else
#      entity =  Entity.find(:first, :conditions => {:id => params[:id], })
#    end
    if params[:database_id]
      entity = Database.find(params[:database_id]).entities.find(params[:id])
    else
      entity = Entity.find(params[:id])
    end
    
    db = entity.database
    entity.destroy
    
    redirect_to :action => 'list', :db => db if params[:controller] == 'admin/entities'
    
    
  end

  # *Description*
  #   This method simply lists the details of an entity.
  #   It was not already there, its added for the sake of REST API
  #
  # GET databases/:database_id/entities/:entity_id/details/list_details
  # GET entity/:entity_id/details/list_details
  # DONE!
  def list_details()
    
      
        if params[:database_id]
          begin 
            entity = Database.find(params[:database_id]).entities.find(params[:entity_id])
          rescue ActiveRecord::RecordNotFound
            respond_to do |format|
              format.html { render :text => 'No details found for the entity', :status => 404 and return }
              format.json { render :json => 'No details found for the entity', :status => 404 and return }
            end
          end
 
        else
          begin
            entity = Entity.find(params[:entity_id])
          rescue ActiveRecord::RecordNotFound
            respond_to do |format|
              format.html { render :text => 'No details found for the entity', :status => 404 and return }
              format.json { render :json => 'No details found for the entity', :status => 404 and return }
            end
          end
        end
      
      if entity == nil
        respond_to do |format|
          format.html {}
          format.json { render :json => 'No details found' and return}
        end
      end
    respond_to do |format|
      format.html { render :text => entity.details.to_json }
      format.json { render :json => entity.details.to_json }
    end
  end
  
  # *Description*
  #   Unlinks the detail from an entity. Or in other words, unlinks a column
  #   from a table. Becuase an entity can use many existing details, it simply
  #   unlinks it them.
  #
  # *Workflow*
  #   The detail to be deleted is picked from detail_id and the entity
  #   requeste is also picked by id.
  #   The method entity.details.delete is called to unlink
  #
  # *REST API*
  #   Call:   UnlinkDetail
  #     Method: POST
  #     Args:
  #       id:         ID of the entity
  #       detail_id:  Detail to be unlinked
  # 
  # PUT databases/4/entities/4/details/3/unlink
  # PUT databases/4/entities/4/unlink_detail
  # 
  # DELETE databases/4/details/3 would delete a detail from the system
  # DELETE databases/4/entities/4/details/3 would unlink
  # So this and all the relevannt methods are 
  # DONE!
  def unlink_detail
    entity = nil
    # From the view, detail_id is the detail id and id is the entity id
    # For rest, we will have database_id, entity_id and id for database,
    # entity and detail respectively.
    
      
      begin
        to_delete = Detail.find params["detail_id"]
        entity = Entity.find params["id"]
        entity.details.delete to_delete
      rescue Exception => e
        flash["error"] = "An error occured: #{e}"
        respond_to do |format|      
          format.html {}
          format.json { render :json => 'Unkown Error', :status => 500 and return }
        end
      end
      
    respond_to do |format|      
      format.html { redirect_to :action => "show", :id => params["id"]}
      format.json { render :json => 'OK Strange!', :status => 200 }
    end
      
 end

  # *Description*
  #   Allows one to choose any existing detail columns.
  #   
  # *Workflow*
  #   The entity of given ID is picked and all of the details of its database
  #   are picked. Then the details of current entity are also picked and excluded
  #   fromt the final list.   
  #
  # *REST API*
  #   Call:   ShowExistingDetailForChoice
  #     Method: GET
  #     Args:
  #       id:         ID of the entity
  # 
  #
  def add_existing_choose
    @entity = Entity.find params["id"]
    all_details = Detail.find(:all, :conditions => ["database_id = ?", @entity.database.id]).collect{|d| d.id.to_i}
    entity_details = @entity.details.collect{|d| d.detail_id.to_i}
    available_details = all_details-entity_details
    if available_details.length>0
      @details = Detail.find(:all, :conditions => "id in (#{available_details.join(",")})")
    else
      @details=[]
    end
  end

  # *Description*
  #   Allows you to chose precision settings of a detail.
  #
  # *REST API:*
  #    id               ID of the entity
  #    detail_id        ID of the detail.
  def add_existing_precisions

    # Pick the entity of the given id with all of its details
    @entity = Entity.find( params["id"], :include => [:details])
    #check the requested detail is not yet linked
    if @entity.details.collect{|d| d.id.to_i}.include?  params["detail_id"].to_i
      flash["error"]=t("madb_error_incorrect_data")
      redirect_to session["return-to"] and return
      #redirect_to :action => "show", :id =>params["id"] and return
    end

    @detail_status = DetailStatus.find(:all)
    @detail = Detail.find params["detail_id"]
    @form_action = "add_existing"
    render :template => "admin/entities/link_details_form"
  end

  # *Description*
  #   Allows you to edit the precisions of a detail.
  #
  def edit_existing_precisions
    @detail_status = DetailStatus.find :all
    #@detail = Detail.find params["detail_id"]
    #@entity = Entity.find params["id"]
    @entity2detail = EntityDetail.find(:first, :conditions => ["entity_id = ? and detail_id = ?", params["id"], params["detail_id"]], :include => [:detail, :entity])
    @detail = @entity2detail.detail
    @entity = @entity2detail.entity

    @displayed_in_list_view = @entity2detail.displayed_in_list_view
    @maximum_number_of_values = @entity2detail.maximum_number_of_values
    @display_order = @entity2detail.display_order



    @form_action = "update_existing_precisions"
    render :template => 'admin/entities/link_details_form'
  end

  def update_existing_precisions
    status = DetailStatus.find params["status_id"]
    #conn = Entity.connection

    @entity2detail = EntityDetail.find(:first, :conditions => ["entity_id = ? and detail_id = ?", params["id"], params["detail_id"]], :include => [:detail, :entity])
    @entity2detail.maximum_number_of_values = params["maximum_number_of_values"]
    @entity2detail.displayed_in_list_view=params["displayed_in_list_view"]
    @entity2detail.status_id=status.id
    @entity2detail.save
    test = EntityDetail.find(:first, :conditions => ["entity_id = ? and detail_id = ?", params["id"], params["detail_id"]], :include => [:detail, :entity])
    
    #update_query = "UPDATE entities2details SET display_order = #{params["display_order"]}, maximum_number_of_values = #{params["maximum_number_of_values"]}, displayed_in_list_view = '#{params["displayed_in_list_view"]}', status_id = #{status.id} WHERE entity_id = #{params["id"]} and detail_id= #{params["detail_id"]}"
    #conn.execute update_query

    redirect_to :action => "show", :id => params["id"]

  end

  # *Description*
  #   Adds and existing detail to this entity
  #   
  # *Workflow*
  #   Entity of the given id is picked along with the detail of the given
  #   detail_id. The status is also picked.
  #   The record is saved in the entitiy2details table.
  #   
  # *REST API:*
  #   * entity.id
  #   * detail_id
  #   * status_id
  #   * displayed_in_list_view
  #   * maximum_number_of_values
  #   * displayed_in_list_view
  #   * display_order
  #   
  # POST entities/:entity_id/details/:id/add_existing
  # POST /databases/:database_id/entities/:entity_id/details/:id/add_existing
  # DONE!
  #
  def add_existing
    entity = Entity.find params["id"]

    

      if entity.details.collect{|d| d.detail_id.to_i}.include?  params["detail_id"].to_i
        flash["error"]=t("madb_error_incorrect_data")
        #FIXME: The format.html blocks do not execute in the tests that's why removed
        # Checkout what's the workaround.
        respond_to do |format|
          format.html { redirect_to :action => "show", :id =>params["id"] and return }
          format.json { render :json => 'Bad Request (detail already belongs to the entity)', :status => 400 and return}
        end
        
      end

      detail = Detail.find params["detail_id"]
      status = DetailStatus.find params["status_id"]
      number_of_details = entity.details.length
      display_order = number_of_details * 10
  #    entity.details.push_with_attributes(detail, {"displayed_in_list_view"=> params["displayed_in_list_view"], "maximum_number_of_values"=> params["maximum_number_of_values"], "display_order" => params["display_order"], "status_id" => status.id })
      entity_detail = EntityDetail.new({"displayed_in_list_view"=> params["displayed_in_list_view"], 
                                    "maximum_number_of_values"=> params["maximum_number_of_values"], 
                                    "display_order" => display_order, "status_id" => status.id })

      entity_detail.detail = detail
      entity_detail.entity = entity
      entity_detail.detail_status = status
      entity_detail.maximum_number_of_values = 1 if !params['maximum_number_of_values']
      entity_detail.save

  #    entity.save
      # format.html do not work in the tests!
      respond_to do |format|
        redirect_to :action => "show", :id => params["id"] and return
        format.json { render :json => 'OK', :status => 200 }
    end
  end

  # *Descirption*
  #   This allows you to define a link. This action only populates
  #   some of the needed field.
  #   
  #   *Workflow*
  #     This simply picks the participants of a link including the 
  #     list of entities, the names of link ends etc.
  #
  def define_link
  #CONTINUER
    if params["child_id"]
      @child_id = params["child_id"]
      @source_id = params["child_id"]
      @this_side = "child_id"
      @this_side_name = "child"
      @other_side = "parent_id"
      @other_side_name = "parent_entity"
      @child_entity = Entity.find(params["child_id"]).name
    else
      @parent_id = params["parent_id"]
      @source_id = params["parent_id"]
      @this_side = "parent_id"
      @this_side_name = "parent"
      @other_side = "child_id"
      @other_side_name = "child_entity"
      @parent_entity = Entity.find(params["parent_id"]).name
    end

    @source = Entity.find( @source_id )
    @relation_types = RelationSideType.find :all
    @entities = Entity.find(:all, :conditions => "database_id= #{@source.database.id}")
    @parent_side_edit = true
    @child_side_edit = true

  end

  # *Description*
  #   Adds a link/relation between two entities.
  #   This function also works as a relation updater if the relation_id
  #   is provided.
  #   
  # *Workflow*
  #   It is checked if the relation_id is given. Then we only be editing it. 
  #   If so, the relation of that
  #   id is picked from the datastore.
  #   
  # FIXME: This function is preforming dual roles, it creates a relation or
  # it updates a relation based on the parameters provided.
  # Therefore, mapping two separate REST calls, the PUT and POST to a single
  # function is not possible. Refactoring needed.
  # For now, we use it to only add the relations by using the POST method
  #
  def add_link
      
      if params["relation_id"]
        @relation = Relation.find params["relation_id"]
        if (params["relation"]["parent_id"] and 
              @relation.parent_id.to_i!=params["relation"]["parent_id"].to_i) or 
              (params["relation"]["child_id"] and 
               @relation.child_id.to_i!=params["relation"]["child_id"].to_i)
          flash["error"]=t("madb_error_incorrect_data")
          # format.html does not works for the tests!
          redirect_to :controller => "databases" and return if params[:controller] == 'admin/entities'
          @msg = 'Bad Request (relation_id and relation params do not agree)' 
          @code = 400 
          return
          
        end
        @relation.update_attributes(params["relation"])
        @msg = 'OK'
        @code = 200
      else
        # Otherwise we would have to create new relation.
        begin
          @relation = Relation.new(params["relation"])
          if !@relation.valid?
            flash["error"]=t("madb_relation_not_created_as_data_was_invalid")
            redirect_to :action => 'show', :id => params[:source_id] and return if params[:controller]  == 'admin/entities'
            @msg = 'Bad Request (relation provided is not valid)'
            @code = 400 
            return
          else
            @relation.save
            @msg = 'OK'
            @code = 201
          end
        rescue
          flash["error"]=t("madb_error_incorrect_data")
          redirect_to :controller => "databases" and return if params[:controller] == 'admin/entities'
          @msg = 'Bad Request (could not save relation)'
          @code = 400 
          return
        end
      end
      redirect_to :action  => "show" , :id => params["source_id"] and return if params[:controller] == 'admin/entities'
      #@msg = 'OK'
      #@code = 201 
  end

  # *Description*
  #   Deletes a link between two entities while the relation id and the source
  #   id (that is, the entity id) is provided.
  #   
  # 
  # FIXME: The format.html blocks do not execute....
  def delete_link
    #check if the link to delete id asked from a related entity (source_id)
    params_validity_count = Relation.count(:conditions => "id = #{params["id"]} and (parent_id=#{params["source_id"]} or child_id=#{params["source_id"]})")
    
    
      
      if params_validity_count.to_i!=1
        flash["error"]=t("madb_error_incorrect_data")
        redirect_to :action => "show", :id => params["source_id"] and return if params[:controller] == 'admin/entities'
        @msg = 'Bad Reqeust (Multiple relation records found.)' 
        @code = 400
        return
      end
      # The above condition to the params_validity_count is added because its
      # only applicable when this function is being used from the web interface.
      # For the REST calls, executing it is not possible neither meaningful.
      # We need to have other means of validation for it.
      
      
      
      begin
        Relation.delete_all "id=#{params["id"]}"
      rescue Exception => e
        logger.warn("Error: #e")
        render :text => "Could not delete relation #{e.to_s}", :status => 500 and return if params[:controller] == 'admin/entities'
          @msg =  "Could not delete relation #{e.to_s}" 
          @code = 500
          return
      end
      redirect_to :action => "show", :id => params["source_id"] and return if params[:controller] == 'admin/entities'
      @msg = 'OK' 
      @code = 200
      return
      
    
  end

  # *Description*
  #   Allows the editing of links. Only you can change the name of the sides yet.
  #
  def edit_link
    begin
      source_entity = Entity.find params["source_id"]
      @relation = Relation.find params["id"]
    rescue
      flash["error"]=t("madb_error_incorrect_data")
      if !request.env["HTTP_REFERER"].nil?
        redirect_to :back and return
      else
        redirect_to :controller => "databases"  and return
      end
    end
    #check validity of parameters
    if (source_entity!=@relation.parent and source_entity!=@relation.child)
      flash["error"]=t("madb_error_incorrect_data")
      if !request.env["HTTP_REFERER"].nil?
        redirect_to :back and return
      else
        redirect_to :controller => "databases"  and return
      end
    end
    @relation_types = RelationSideType.find :all
    @entities = Entity.find(:all, :conditions => "database_id=#{source_entity.database_id}")
    @source_id = params["source_id"]
    if @relation.parent == source_entity
      @this_side = "parent_id"
      @other_side = "child_id"
      @other_side_name= "child_entity"
    else
      @this_side="child_id"
      @other_side = "parent_id"
      @other_side_name= "parent_entity"
    end
    @parent_side_edit = true if @relation.parent_side_type.name=='one'
    @child_side_edit = true if @relation.child_side_type.name=='one'
    @parent_entity = @relation.parent.name
    @child_entity = @relation.child.name

    render :template => 'admin/entities/define_link'

  end
  
  #PENDING: Understand and document.
  def reorder_details
#{"entity_detail"=>"11", "action"=>"reorder_details", "controller"=>"admin/entities", "_"=>"", "entity_details"=>["48", "49", "50", "51", "53", "52", "54", "55", "62", "63"]}
    entity = Entity.find params["id"]
    ordered_ids = params["entity_details"]
    current_ordered_details = EntityDetail.find(:all, 
                            :conditions=> ["entity_id=?", params["id"].to_i]).sort{|a,b| a.display_order.to_i<=>b.display_order.to_i}

    current_ordered_details.each_index do |i|
      current_detail = current_ordered_details[i]
      next if current_detail.detail_id.to_i == ordered_ids[i].to_i and current_detail.display_order.to_i==i*10
      new_detail = EntityDetail.find :first,:conditions => ["entity_id=? and detail_id=?",params["id"],ordered_ids[i]]
      #next if detail_not found. Could be we passed a bad detail_id
      if new_detail.nil?
        logger.warn("ERROR: detail_id #{ordered_ids[i]} not found for entity #{params["id"]}")
        next
      end
      new_detail.display_order = i*10
      new_detail.save
    end
    render :nothing => true

  end

  def toggle_public_form
    entity = Entity.find params['id']
    entity.has_public_form=params["value"]
    entity.save
    render :nothing => true
  end
  
end  
  
  

