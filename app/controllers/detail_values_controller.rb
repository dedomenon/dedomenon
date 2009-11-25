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
#   This class allows to manipulate the detail values.
#
#
class DetailValuesController < ApplicationController

  before_filter :login_required
  before_filter :check_all_ids
  def check_all_ids
        begin
          @db = DetailValue.find(params["id"]).instance.entity.database
        rescue ActiveRecord::RecordNotFound
          flash["error"]=t("madb_error_data_not_found")
          redirect_to :controller => "database" and return false
        end
        if ! user_dbs.include? @db
          flash["error"] = t("madb_entity_not_in_your_dbs")
          redirect_to :controller => "database" and return false
        end
  end

  def delete
    v = DetailValue.find params["id"]
    v.destroy
    render :nothing => true
  end
end
