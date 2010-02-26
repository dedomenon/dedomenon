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
require 'database_controller'

# Re-raise errors caught by the controller.
class DatabaseController; def rescue_action(e) raise e end; end

class DatabaseControllerTest < ActionController::TestCase
  fixtures :accounts,:user_types, :users, :databases, :entities
  def setup
    @controller = DatabaseController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_list_with_correct_user
    user = User.find_by_id(2)
     get :index, {}, { 'user' => user, 'account_id' => user.account_id }
     assert_response :success
     assert_equal 1, assigns["databases"].length
     assert_equal 6, assigns["databases"][0].id
  end
	
  def test_list_with_correct_user_expired_account
    user = User.find_by_id(1000011)
    get :index, {}, { 'user' => user, 'account_id' => user.account_id }
    assert_response :redirect
    assert_redirected_to :controller => "authentication", :action => "login"
  end
  
  def test_list_with_correct_user_account_to_be_cancelled_next_week
    user = User.find_by_id(1000010)
    user.account.end_date = Time.now.next_week.to_date
    get :index, {}, { 'user' => user, 'account_id' => user.account_id }
    assert_response :success
  end

  def test_list_with_correct_user_account_cancelled_last_month
    user = User.find_by_id(1000010)
    user.account.end_date = Time.now.last_month.to_date
    get :index, {}, { 'user' => user, 'account_id' => user.account_id }
    assert_response :redirect
    assert_redirected_to :controller => "authentication", :action => "login"
  end


  def test_list_with_correct_user
    user = User.find_by_id(2)
    get :list_entities, {:id =>6 }, { 'user' => user, 'account_id' => user.account_id }
    assert_response :success
    assert_equal 14, assigns["entities"].length
  end
  
	
  def test_list_with_incorrect_user
    user = User.find_by_id(2)
    get :list_entities, {:id =>3 }, { 'user' => user, 'account_id' => user.account_id }
    assert_response :redirect
    assert_redirected_to  :controller=> "database"
    assert_equal  "madb_database_not_in_your_dbs", flash["error"]
  end
  
end
