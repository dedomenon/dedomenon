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
#   This controller allows the user to list all the database or
#   the entities of a particular database.
#
class DatabaseController < ApplicationController
  before_filter :login_required
  before_filter :check_all_ids

  # *Description*
  #   Checks whether the required parameters are present in the request.
  #   Sets the isntance variable @db for the given database.
  def check_all_ids
    if params["id"]
      begin
        @db = Database.find(params["id"])
      rescue ActiveRecord::RecordNotFound
        flash["error"]=t("madb_error_data_not_found")
        redirect_to :controller => "database" and return false
      end
      
      if ! user_dbs.include? @db
        flash["error"] = t("madb_database_not_in_your_dbs")
        redirect_to :controller => "database" and return false
      end
    end
  end

  # *Description*
  #   Lists all the databases of the account.
  #
  def index
    @databases = Database.find(:all, :conditions => ["account_id = ?", session["user"].account_id])
    if @databases.kind_of? Database
      @databases = [ @databases ]
    elsif @databases.nil?
      @databases = []
    end
    @title = t("madb_list_of_databases")
  end

  # *Description*
  #   Lists all the entities of the given database.
  #
  def list_entities
    @entities = Entity.find(:all, :conditions => "database_id = #{params["id"]}")
    # Ain't it enoough to rely on @db set by the check_all_ids ?
    @database = Database.find params["id"]
    @title = t("madb_entities_list", :vars => { 'db' => @database.name})
  end
end
