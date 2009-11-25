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

require_dependency "user"

module LoginSystem
  module AuthSchemes
    def accept_auth(*a)
      @auth_schemes=a
      #accepts :session :http_basic_auth  :api_key
    end
    attr_reader :auth_schemes
  end

  protected
  def accepted_auth_schemes
    self.class.auth_schemes || [:session]
  end

  # overwrite this if you want to restrict access to only a few actions
  # or if you want to check if the user has the correct rights
  # example:
  #
  #  # only allow nonbobs
  #  def authorize?(user)
  #    user.login != "bob"
  #  end
  def authorize?(user)
     not user.nil? and user.verified? and user.account.allows_login?
  end

  # overwrite this method if you only want to protect certain actions of the controller
  # example:
  #
  #  # don't protect the login and the about method
  #  def protect?(action)
  #    if ['action', 'about'].include?(action)
  #       return false
  #    else
  #       return true
  #    end
  #  end
  def protect?(action)
    true
  end

  # login_required filter. add
  #
  #   before_filter :login_required
  #
  # if the controller should be under any rights management.
  # for finer access control you can overwrite
  #
  #   def authorize?(user)
  #
  def user_logging_in
    @user = nil
    method = accepted_auth_schemes.detect do |s|
      @user = send("login_with_#{s}") 
    end
    return @user
      
  end

  def current_user
    @user
  end


  def login_required

    if not protect?(action_name)
      return true
    end

    if authorize?(user_logging_in)
      return true
    end
    return false if attempting_http_basic_auth?

    # store current location so that we can
    # come back after the user logged in
    store_location

    # call overwriteable reaction to unauthorized access
    access_denied
    return false
  end

  def login_with_session
     session["user"]
  end

  def attempting_http_basic_auth?
    @attempting_http_basic_auth
  end
  def login_with_http_basic_auth
    #return session["user"] if session["user"]
    @attempting_http_basic_auth=true
    user=nil
#    request_http_basic_authentication 'Web Password' and return nil  unless ActionController::HttpAuthentication::Basic.authorization(request)
    authenticate_or_request_with_http_basic do |login, password|
      user = User.authenticate(login, password)
    end
    return user
  end

  def get_api_key_from_request
    return params['api_key']
  end
  def login_with_api_key
    if params['api_key']
      return User.find_by_api_key( get_api_key_from_request ) 
    end
  end
  # overwrite if you want to have special behavior in case the user is not authorized
  # to access the current operation.
  # the default action is to redirect to the login screen
  # example use :
  # a popup window might just close itself for instance
  def access_denied
      respond_to do |format|
        format.html do
          redirect_to :controller=>"/authentication", :action =>"login"
        end
        #format.any(:json, :xml) do
        #  request_http_basic_authentication 'Web Password'
        #end
      end
  end

  # store current uri in  the session.
  # we can return to this location by calling return_location
  def store_location
    session['return-to'] = request.request_uri
  end

  # move to the last store_location call or to the passed default one
  def redirect_back_or_default(default)
    if session['return-to'].nil?
      redirect_to default
    else
      redirect_to session['return-to']
      session['return-to'] = nil
    end
  end

end
