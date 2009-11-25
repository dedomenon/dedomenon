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

require File.dirname(__FILE__) + '/../test_helper'
require 'settings_controller'

# Re-raise errors caught by the controller.
class SettingsController; def rescue_action(e) raise e end; end

class SettingsControllerTest < ActionController::TestCase
  fixtures :users, :preferences
  def setup
    @controller = SettingsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @user_id_with_help = 2
    @admin_user_id = 2
    @normal_user_id = 1000001
    @user_id_without_help = 1000003
  end

  def test_show_without_logged_in
    #------------------------------------
     get :show, {}, {}
     assert_response :redirect
     assert_redirected_to :controller => "authentication", :action => "login"
  end

  def test_option_choice
    get :show, {}, { 'user' => User.find_by_id(@user_id_with_help)}
    assert_response :success
    assert_tag :tag => "option", :attributes => { :selected => "selected", :value => "true" }, :content => "madb_yes"
    #help is displayed
    assert_tag :tag => "div", :attributes => { :class => "help" }
    #check return-to is set
    assert_match Regexp.new(@request.session['return-to']) , @controller.url_for(:controller => "settings", :action => "show")
    

    get :show, {}, { 'user' => User.find_by_id(@user_id_without_help)}
    assert_response :success
    assert_tag :tag => "option", :attributes => { :selected => "selected", :value => "false" }, :content => "madb_no"
    #no help is displayed
    assert_no_tag :tag => "p", :attributes => { :class => "help" }
  end


  def test_help_setting_change
    assert !User.find(@user_id_without_help).preference.display_help?
    post :apply, {"commit"=>"madb_submit", "setting"=>{"display_help"=>"true"}} , { 'user' => User.find_by_id(@user_id_without_help)}
    assert_response :redirect
    assert_redirected_to :controller => "settings", :action => "show"

    assert User.find(@user_id_without_help).preference.display_help?
  end

end
