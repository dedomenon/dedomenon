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
#   This class deals with the details of entites.
# FIXME: This needs REST interfacing yet!
class Admin::DetailsController < ApplicationController
  before_filter :login_required
  before_filter :check_user_rights
  before_filter :check_all_ids
  before_filter :set_return_url , :only => ["list", "index"]
  verify :method => 'post', :redirect_to => {:controller => "databases"}, :only => "destroy" if self.class.to_s == 'Admin::DetailsController'

  # *Description*
  #   Checks whether the user is an admin or not.
  #
  def check_user_rights
    
    #return true if params[:controller] == 'rest/details'
    
    if !session["user"].admin_user?
      if params[:controller] == 'admin/details'
        flash["error"]=t("madb_you_dont_have_sufficient_credentials_for_action")
        redirect_to :controller => "/database" and return false
      elsif params[:controller] == 'rest/details'
        if %w{create update destroy}.include? params[:action]
          msg = {:errors => ['This REST call needs administrative rights']}
          render :json => msg.to_json, :status => 403 and return false
        end
      end
    end
  end
  
  # *Description*
  #   Checks whether all the required ids for the intended action are provided
  #   in the request or not. See source code for further comments regarding
  #   working.
  #
  def check_all_ids
    
    # We will return true if its a REST call because
    # the validation would be done in the REST controller.
    return true if params[:controller] == 'rest/details'
     
    
    
    if params["id"]
      detail_ids = []
      session["user"].account.databases.each do |db|
        detail_ids.concat db.details.collect{|d| d.id}
      end
      # If the provided id is not in the ids gathered above
      if ! detail_ids.include? params["id"].to_i
        flash["error"] = t("madb_error_incorrect_data")
        redirect_to :controller => "databases", :action => "list" and return false
      end
      @db = Detail.find(params["id"]).database
    end
    
    # if the db params is provided, check
    # whether that database belongs to the user or not.
    if params["db"] and params["db"]!=""
      begin
        @db = Database.find params["db"]
      rescue
        flash["error"] = t("madb_error_incorrect_data")
        redirect_to :controller => "databases" and return false
      end
      if ! user_admin_dbs.include? @db
        flash["error"] = t("madb_entity_not_in_your_admin_dbs")
        redirect_to :controller => "databases" and return false
      end
    end

    # if the intended action is to list/index the details of a database
    # and the database id (that is, params[:db]) is not provided
    if %w{list index}.include? params["action"] and !params["db"]
        flash["error"] = t("madb_error_incorrect_data")
        redirect_to :controller => "databases" and return false
    end
    
    # if the intended action is to create/list/new detail
    # and the relevant database and entity ids are not provided.
    if %w{create new list}.include? params["action"]
      if !params["for_entity"] and !params["db"]
        flash["error"] = t("madb_error_incorrect_data")
        redirect_to :controller => "databases" and return false
      end
    end

  end
  
  # *Description*
  #   Shows the list of details of a database.
  #
  def index
       
    list    
    render :action => 'list' if params[:controller] == 'admin/details'
      
    
  end

  # *Description*
  #   Finds the details of a database.
  #
  def list
    # This case is only for where /entities/details is to be get.
    # For the /databases/details its simply to do
    # For a nested call like /databases/entities/details is also simple
    # except that the details not belonging to the given entity are excluded.
    if !params[:database_id] and params[:entity_id] and !params[:db]
      entity = Entity.find(params[:entity_id], :include=> :entity_details)
      
      @details = []
      entity.entity_details.each do |entity_detail|
        @details.push(Detail.find(entity_detail.detail_id.to_i))
      end
      return
    end
    # If a database is proivded
    if params[:db]
      @details = Detail.find(:all, 
        :offset => params['start-index'], 
        :limit => params['max-results'], 
        :conditions => ["database_id=?",params[:db]], :order => "lower(name)") 
      # If an entity is also mentioned, then we need to sort out the 
      # details that do not belong to the provided entity.
      if params[:entity_id]
        # This sentence in Greek removes the details that do not belong
        # to the provided entity in params[]! :-D
        # Not much expert in Ruby like me?
        # Read from left to right!
        @details.collect! { |detail| detail if detail.entities.collect{ |entity2detail| entity2detail.entity_id.to_i}.include?(params[:entity_id].to_i) }
      end
    else
      @details = Detail.find(:all, 
        :offset => params['start-index'], 
        :limit => params['max-results'], 
        :order => "lower(name)")
    end
       
  end

  # *Description*
  #   Shows a particular detail.
  # FIXME: Look at the propositions stuff. How should we return them?
  def show
    edit
  end

  # *Description*
  #   Renders a form for new details.
  #
  def new
    @details = Detail.new
    @data_types = DataType.find(:all).collect{ |dt| [t(dt.name), dt.id]}
    @choose_in_list_id = DataType.find_by_name("madb_choose_in_list").id
    @propositions = []
  end

  # *Description*
  #   Creates a new entity.
  #   
  #
  def create
    
    @details = Detail.new(params[:details])
    @details.name = @details.name.gsub(/ /,"_")
    @details.name = @details.name.gsub(/'/,"_")
    # This complete if block is used to select the database from either
    # the entity.id or from db param
    if params["for_entity"]
      begin
        @entity = Entity.find(params["for_entity"])
        db = @entity.database
      rescue
        flash["error"] = t("madb_error_incorrect_data")
        redirect_to :controller => "databases" if params[:controller] == 'admin/details'
        @msg = "Bad Request (Entity[#{params[:for_entity]}] not found)" 
        @code = 400
        return
      end
    else
      begin
        db = Database.find(params["db"])
      rescue
        flash["error"] = t("madb_error_incorrect_data")
        redirect_to :controller => "databases" and return if params[:controller] == 'admin/details'
        @msg = "Bad Request (Database[#{params[:db]}] not found)" 
        @code = 400 
        return
      end
    end
    @details.database = db

    # Save the propositon values if the datatype is propositon type and 
    # propositions are provided.
    params["propositions"].each do |p|
    @details.detail_value_propositions << DetailValueProposition.new( "value" => p)
    end if params["propositions"] and @details.data_type==DataType.find_by_name("madb_choose_in_list")


    # 
    if @details.save
      flash['notice'] = 'Details was successfully created.'
      
      
      if params["for_entity"]
        if params["quick_commit"]
          number_of_details = @entity.details.length
          display_order = number_of_details * 10
          redirect_to :controller => 'entities', 
                        :action => 'add_existing', 
                        :detail_id=> @details.id, 
                        :id => params["for_entity"], 
                        :status_id => 1, 
                        :displayed_in_list_view => true, 
                        :maximum_number_of_values => 1, 
                        :display_order => display_order and return if params[:controller] == 'admin/details'
            @msg = 'OK' 
            @code = 201
            return
          
        else
          
          
          redirect_to :controller => 'entities', 
                      :action => 'add_existing_precisions', 
                      :detail_id=> @details.id, 
                      :id => params["for_entity"]  if params[:controller] == 'admin/details'
            @msg = 'OK' 
            @code = 201 
            return
          
             
        end
      else
        redirect_to :action => 'list', :db => params["db"] and return if params[:controller] == 'admin/details'
        @msg = 'OK'
        @code = 201
        return
      end
    else
    @data_types = DataType.find(:all).collect{ |dt| [t(dt.name), dt.id]}
    @choose_in_list_id = DataType.find_by_name("madb_choose_in_list").id
    @propositions= params["propositions"]||[]
    render :action => 'new' and return if params[:controller]  == 'admin/details'
    @msg =  'Internal Server Error' 
    @code = 500
    @details.errors.each do |error|
      @msg +="\n"
      error.each do |item, reason|
        @msg += "\t#{item}:\t #{reason}\n"
      end
    end
    return
    end
  end

  # *Description*
  #   Allow editing of an existing detail.
  #
  def edit
    @data_types = DataType.find(:all).collect{ |dt| [t(dt.name), dt.id]}
    @choose_in_list_id = DataType.find_by_name("madb_choose_in_list").id
    @details = Detail.find(params[:id])
    @propositions = @details.detail_value_propositions.collect{|p| [ p.value, p.id ]}
  end

  # *Description*
  #   Alows updating a detail.
  #
  def update
    if params[:database_id]
      @details = Detail.find(:first, :conditions => ["database_id = ? and id = ?", params[:database_id], params[:id]])
    else
      @details = Detail.find(params[:id])
    end
    
    #FIXME This is turned from only editing the name of the detail to complete
    #udpate of the attributes because this was needed for the optimistic concurrencty
    # However, in order to achieve same effect, the fields of the Detail model
    # are made readonly.
    #@details.name=params[:details]["name"]
    @details.update_attributes!(params[:details])
    if @details.save
      flash['notice'] = t 'notice_update_successful'
      redirect_to :action => 'list', :db => @details.database_id if params[:controller] == 'admin/details'
      @msg = 'OK'
      @code = 200
      return
    else
      render :action => 'edit' and return if params[:controller] == 'admin/details'
      @msg = 'Internal Server Error'
      @code = 500
      return 
    end
      
    
  end

  # *Description*
  #   Destroys a detail.
  def destroy
    Detail.find(params[:id]).destroy
    redirect_to :back and return if params[:controller] == 'admin/details'
    @msg = 'OK'
    @code = 200
    return
  end
end

