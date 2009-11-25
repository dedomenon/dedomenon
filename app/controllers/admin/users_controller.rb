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
#   This controller allows to create new users, edit existing ones and
#   delete them also. All the services related to user management are
#   gathered in this controller.
#
class Admin::UsersController < ApplicationController

  before_filter :login_required
  before_filter :check_user_rights
  before_filter :check_all_ids

  # *Description*
  #   Checks whether the current user is an admin?
  def check_user_rights
    #return true if params[:controller] == 'rest/users'
    if !session["user"].admin_user?
      if params[:controller] == 'admin/users'
        flash["error"]=t("madb_you_dont_have_sufficient_credentials_for_action")
        redirect_to :controller => "/database" and return false
      elsif params[:controller] == 'rest/users'
        if %w{create update destroy}.include? params[:action]
          msg = {:errors => ['This REST call needs administrative rights']}
          render :json => msg.to_json, :status => 403 and return false
        end
      end
    end
  end
  
  # *Description*
  #   Checks whether the id of the current user is associated with current
  #   account or not.
  # FIXME: Change it to accept nestd URL
  def check_all_ids
    return true if params[:controller] == 'rest/users'
    if params["id"]
      if ! session["user"].account.users.collect{|u| u.id}.include? params["id"].to_i
          redirect_to :controller => "/admin/users", :action => "list" and return false
      end
    end
  end

  # *Description*
  #   Resets the password of the user.
  #
  def reset_password
    @user = User.find params["id"]
    @newpass = @user.makepass
    @user.change_password(@newpass)
    Notify.deliver_change_password(@user, @newpass, url_for(:controller => "/authentication", :action => "login"), user_lang )
    flash["notice"] = t("madb_password_reset_mail_sent") #+ newpass
    redirect_to :action => "list"
  end

  # *Description*
  #   Renders the list of users.
  #
  # GET account/1/users.json
  
  
  def index
    list
    
    
    render :action => 'list' if params[:controller] == 'admin/users'
      
   end

  # *Description*
  #   Lists the users of current account
  # FIXME: Modify the code such that if session user is not present,
  # Then it should require the account id. That would be done with the help
  # of nested resources.
  def list
    session["user"].reload
    @users =session["user"].account.users.sort{|a,b| a.login<=>b.login}
    @users_pages = Paginator.new self, @users.length, 10
    
    # If its a REST call, then we are going to search differently
    @users = User.find( :all, 
                        :offset => params['start-index'],
                        :limit => params['max-results'],
                        :conditions => ["account_id=?", params[:account_id]]) if params[:controller] == 'rest/users'
    #@users_pages = nil
  end

  # *Description*
  #   Shows details of a particular user.
  #   GET account/1/users/3.json
  #   
  # FIXME: Update for nested resoruces.
  def show
    @account = Account.find(params[:account_id])
    #@users = User.find(params[:id])
    @users = @account.users.find(params[:id])
    
    # If the call is from a REST controller then
    @users = User.find(params[:id]) if params[:controller] == 'rest/users'
  end

  # *Description*
  #   Creates a new user.
  def new
    @user = User.new
    @user_types_for_select = UserType.find(:all).collect{ |t| [ t(t.name) , t.id ]}
  end

  # *Description*
  #   Creates a new user based on the infomration recieved.
  #   
  # POST /users.format
  # FIXME: Modify the function such that its able to handle the nested
  # resources.
  
  def create
    @user_types_for_select = UserType.find(:all).collect{ |t| [ t(t.name) , t.id ]}
    @user = User.new(params[:user])
    @user.account = session["user"].account
    @newpass = @user.makepass
    @user.password = @newpass
    @user.password_confirmation = @newpass
    @user.verified = 1
    if @user.save
      flash['notice'] = t('madb_users_was_successfully_created')
      Notify.deliver_change_password(@user, @newpass, url_for(:controller=> "/authentication", :action => "login"))
      redirect_to :action => 'list' if params[:controller] == 'admin/users'
      @msg = 'OK'
      @code = 201 
    else
      render :action => 'new' if params[:controller] == 'admin/users'
      @msg = "Bad Request" 
      @code = 400
    end
  end

  # *Description*
  #   Allows editing a user
  def edit
    @users = User.find(params[:id])
  end

  # *Description*
  #  Updates a user
  # PUT accounts/id.format
  # user is the expected data using the rails form field conventions.
  # FIXME: Modify to act with the nested resources!
  def update
    @users = User.find(params[:id])
    #NOTE: We change it from users to user!
    if @users.update_attributes(params[:user])
      flash['notice'] = 'Users was successfully updated.'
      redirect_to :action => 'show', :id => @users.id if params[:controller] == 'admin/users'
      @msg = 'OK'
      @code = 200
    else
      render :action => 'edit' if params[:controller] == 'admin/users'
      @msg = "Bad Request" 
      @code = 400 
    end
  end

  # *Description*
  #   Deletes a user from the system.
  #   DELETE accounts/id.format
  #
  def destroy
    user_to_destroy = User.find params["id"]
    if user_to_destroy.user_type.name=="primary_user"
      flash["error"] = t("madb_error_primary_user_cannot_be_deleted")
      redirect_to :action => 'list' and return if params[:controller] == 'admin/users'
      @msg = "Forbidden"
      @code = 403 
    else
      user_to_destroy.destroy
        redirect_to :action => 'list'and return if params[:controller] == 'admin/users'
        @msg = "OK" 
        @code = 200
    end
  end
  
end
