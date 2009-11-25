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

class SettingsController < ApplicationController

  before_filter :set_return_url , :only => ["show"]
  before_filter :login_required 
  before_filter :admin_user_required, :only => ["confirm_vat"] 
  layout :determine_layout

  def determine_layout
    return nil if request.xhr?  or params["action"] == "vat_form"
    return "application"
  end

  def show
    @preferences = session["user"].preference||Preference.new(:user => session["user"])
    @display_help_options = [[ t("madb_yes"), "true"],[ t("madb_no"), "false"]]
  end

  def apply
    @preferences = session["user"].preference||Preference.new(:user => session["user"])
    @preferences.update_attributes(params["setting"])
    if @preferences.save
      flash["warning"] =t("madb_settings_could_not_be_saved")
    else
      flash["notice"] =t("madb_settings_saved")
    end
    redirect_to :action => "show"
  end

end
