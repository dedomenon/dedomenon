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

# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.
# 
  require_dependency "login_system"
  require_dependency "translations"
class ApplicationController < ActionController::Base
    include LoginSystem
    extend LoginSystem::AuthSchemes
    helper_method :current_user
    include Translations
  
  before_filter :set_user_lang
    
    #model :user
    #model :translation


  # This url is the base url of the application
  # Note that it is an adhoc solution for now.
  # We will make the application to generate this
  # automatically later on.
  @@base_url = 'http://localhost:3000/'
  
  
  helper_method :t
  after_filter :set_encoding, :except => ["apply_edit", "apply_link_to_new", "link", "download"] #downlod is in file_attachment_controller
    
  # *Description*
  #   Sets the encoding for the responce to be UTF-8
  def set_encoding
    unless ["csv", "js"].include? params["format"]
      response.headers["Content-Type"] = "text/html; charset=UTF-8"
    end
  end


  #from a module included in config/environment.rb
  helper_method :class_from_name

  # *Description*
  #   Returns the databases of the user.
  def user_dbs
    return [] if session["user"].nil?
    session["user"].account.databases
  end

  # *Description*
  #   Returns the databases of the user.
  def user_admin_dbs
    session["user"].account.databases
  end


# PENDING: Document and understand this method

  # *Description*
  #  Returns true if the action is part of the request instead of the URL
  def embedded?
    ( params["action"]!=request.path_parameters["action"])
  end
  helper_method :embedded?

  # *Description*
  #   Sets the return path of the session
  def set_return_url
    session['return-to'] = request.request_uri
  end

  # *Description*
  #   Returns the account id
  #
  def get_account_id
    return session["user"].account_id
  end

  # Returns the Database ID
  def get_database_id
    return @db.id if @db
    return nil
  end

  #was necessary to have request not considered local.
  def local_request?
      false
  end

  def rescue_action_in_public(exception)
    case exception.class.to_s
    #, ActionController::UnknownAction
    when "ActiveRecord::RecordNotFound","ActionController::RoutingError"
      render(:file => "#{RAILS_ROOT}/public/404.html",
             :status => "404 Not Found")
    else
      render(:file => "#{RAILS_ROOT}/public/500.html",
             :status => "500 Error")
      SystemNotifier.deliver_exception_notification(self, request, exception)
    end
  end

  def admin_user_required
     if  !session["user"].admin_user?
       redirect_to :controller => "authentication", :action => "login" and return false
     end
     return true
  end
  
  

end

