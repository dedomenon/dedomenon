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
#   This class lets the administrator manage the databases.
# *REST API Considerations*
#   * Ability to list the databases
#   * Create a database
#   * Delete a database
#   * Update a database
#   * Get the tables of a database
#   * Raph: Let me know what else?
#

class Admin::DatabasesController < ApplicationController
  before_filter :login_required
  before_filter :check_user_rights
  before_filter :check_all_ids

  # *Description*
  #     Checks whether the user in current session has rights to access the
  #     databases?
  #     
  # *Workflow*
  #     If the user in the current session is not admin user, a flash message
  #     is registerd and user is redirected to databases controller.
  #
  def check_user_rights
    #return true if params[:controller] == 'rest/database_controller'
    
    if !session["user"].admin_user?
      if params[:controller] == 'admin/databases'
        flash["error"]=t("madb_you_dont_have_sufficient_credentials_for_action")
        redirect_to :controller => "/database" and return false
      elsif params[:controller] == 'rest/databases'
        if %w{create update destroy}.include? params[:action]
          msg = {:errors => ['This REST call needs administrative rights']}
          render :json => msg.to_json, :status => 403 and return false
        end
      end
    end
  end
  
  # *Description*
  #   Checkes whether the database demanded for manipulation belongs to
  #   the current user or not.
  #   
  #  *Workflow*
  #   If id is present in the parameters, database of that ID is fetched and 
  #   it is checked if that database is present in the databases of the user
  #   of current session. If the database is not in the list of the databases,
  #   the user is directed to admin/users controller.
  #   
  def check_all_ids
    return true
    return true if params[:controller] == 'rest/database_controller'
    
    if params["id"]
      begin
        @db = Database.find params["id"]
      rescue ActiveRecord::RecordNotFound
        flash["error"]=t("madb_error_data_not_found")
        redirect_to :controller => "databases" and return false
      end
      if ! session["user"].account.databases.collect{|d| d.id}.include? @db.id
          redirect_to :controller => "/admin/users", :action => "list" and return false
      end
    end
  end
  
  # *Description*
  #   Lists all the databases of the user.
  #   
  # *Workflow*
  #   Calls the list method and then renders the list layout.
  #
  def index
    list
    render :action =>  'list' if params[:controller] == 'admin/databases'
  end

  # *Description*
  #   Finds all the databases associated with this account.
  #
  def list
    if params[:name]
      begin
        @databases = Database.find(:first, :conditions => ["name = ?", params[:name]])
      rescue ActiveRecord::RecordNotFound
        @databases = nil
      end
    elsif params[:account_id]
      @databases = Database.find(:all,  
        :offset => params['start-index'], 
        :limit => params['max-results'], 
        :conditions => ["account_id = ?", params[:account_id]])
    else
      @databases = Database.find(:all, 
        :offset => params['start-index'], 
        :limit => params['max-results'], 
        :conditions => ["account_id = ?", session["user"].account.id])
    end
  end

  # *Description*
  #   Shows a database attributes.
  def show
    @database = Database.find(params[:id])
  end

  # *Description*
  #   Creates a new database.
  #
  def new
    @database = Database.new
  end

  # *Description*
  #   Saves a newly created database to the datastore
  #   
  # *Workflow*
  #  A new database is created and saved.
  
  def create
    @database = Database.new(params[:database])
    
    
    # Only pick set to current account if its being called from view.
    @database.account = session['user'].account if params[:controller] == 'admin/databases'
    
      if @database.save
        flash['notice'] = 'Database was successfully created.'
        redirect_to :action => 'list' if params[:controller] == 'admin/databases'
        @msg = 'OK'
        @code = 201
      else
        render :action => 'new' if params[:controller] == 'admin/databases'
        @msg = "Failed: #{@database.errors.full_messages.join(' ')}"
        @code = 400
      end
    
    
  end

  # Allows editing in a database
  def edit
    @database = Database.find(params[:id])
  end

  # Updates a database from the recieved attributes.
  def update
    @database = Database.find(params[:id])
    
    
    if @database.update_attributes(params[:database])
      flash['notice'] = 'Database was successfully updated.'
      redirect_to :action => 'list' if params[:controller] == 'admin/databases'
      @msg = 'OK'
      @code = 200
    else
      render :action => 'edit' if params[:controller] == 'admin/databases'
      @msg = 'Bad Request'
      @code = 400
    end
    
  end

  def destroy
    Database.find(params[:id]).destroy
    redirect_to :action => 'list' if params[:controller] == 'admin/databases'
  end
end

