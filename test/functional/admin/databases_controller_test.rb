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

require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/databases_controller'

# Re-raise errors caught by the controller.
class Admin::DatabasesController; def rescue_action(e) raise e end; end

class Admin::DatabasesControllerTest < ActionController::TestCase
  fixtures   :account_types, 
             :accounts,
             :databases,
             :user_types, 
             :users, 
             :entities, 
             :data_types, 
             :detail_status, 
             :details, 
             :instances, 
             :detail_values

  # *Description*
  #   Sets an instance of controller, request and responce.
  # 
  def setup
    @controller = Admin::DatabasesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @db1_number_of_entities = 8 
    @db1_admin_user_id = 2
    @db1_normal_user_id = 1000001
    @db1_entity_id = 11
    @db1_instance_id = 77
    @db2_user_id= 1000003
    @db2_admin_user_id = 1000004
  end

	##############
	#index
	##############
        
  # *Description*
  #   Basically here we test whether we can reach the databases when
  #   We are an admin user?
  #   
  #   *Strategy*
  #     First we load a user from the fixtures and execute a
  #     +get+ call with a session data of 'user' => loadedFixture user
  #     And account ID to be user.account_id
  #     The we expect following:
  #        * The responce code should be success
  #        * The rendered template should be 'list'
  #        
  #
  def test_index_with_correct_user
    user = User.find_by_id(@db1_admin_user_id)
    get :index, {} , { 'user' => user, 'account_id' => user.account_id }
    
    assert_response :success
    assert_template 'list'
    assert_equal 4, assigns["databases"].length
  end

  # *Description*
  #   We are testing to list the database as a non admin user.
  #
  # *Strategy*
  #   We get the index page with setting the session variable 
  #   'user' as a non admin user from the fixture data.
  #   Then we expect following:
  #     * The response is redirect
  #     * We are redirected to database controller
  #
  def test_index_with_non_admin_user
    get :index, {} , { 'user' => User.find_by_id(@db1_normal_user_id)}
    assert_response :redirect
    assert_redirected_to  :controller => "/database"
  end

  # *Description*
  #   We try to list the database with an incorrect user.
  #   
  #  *Strategy*
  #   We get the index page with an incorrect user ID.
  #   We expect following:
  #      * Response is to redirect
  #      * We are redirected to databases controller
  #
  def test_index_with_incorrect_user
    get :index, {} , { 'user' => User.find_by_id(@db2_user_id)}
    assert_response :redirect
    assert_redirected_to  :controller => "/database"
  end

  # *Description*
  #   We try to get the index page while we are not logged in.
  #   
  # *Strategy*
  #   We get the index page.
  #   We expect the following:
  #     * We are redirected to authentication.
  #
  def test_index_with_no_user
    get :index, {} , {}
    assert_response :redirect
    assert_redirected_to  :controller => "/authentication"
  end

  # *Description*
  #   We try to create a new database with a correct user.
  #   
  #  *Strategy*
  #   We hit the new action with setting the session variables of user and
  #   the account_id.
  #   We expect following:
  #     * responce is success
  #     * There is a tag <input type="text" name="database[name]">
  #
  def test_new_with_correct_user
    user = User.find_by_id(@db1_admin_user_id)
    get :new, {} , { 'user' => user, 'account_id' => user.account_id }
    assert_response :success
    assert_tag :tag => "input",:attributes =>{ :type => "text", :name => "database[name]"}
  end

  # *Description*
  #   We test to create a new database with a correct user.
  #   
  #   *Strategy*
  #     We obtaint the database count and then fire the post action on create
  #     action of the controller admin/databases with a database parameter hash
  #     containing the name of the database along with settign the session
  #     variable user to the user.
  #     Afterwards, we obtain the databse coutn again.
  #     We expect the following:
  #       * Response is to redirect
  #       * We are redirected to DatabasesController#list
  #       * The difference between the pre and post database count is 1
  #
  def test_create_with_correct_user
    pre_databases_count = Database.count
    post :create, {"controller"=>"admin/databases", "database"=>{"name"=>"hjhj"}}, { 'user' => User.find_by_id(@db1_admin_user_id)}
    post_databases_count = Database.count

    #redirected to db list
    assert_response :redirect
    assert_redirected_to :action => "list"
    #one db created
    assert_equal 1, post_databases_count - pre_databases_count
  end
 
  # *Description*
  #   We try to create a database with a correct user whose account limit is 
  #   reached.
  #   
  #  *Strategy*
  #   We get the database count then we invoke then we invoke the 
  #   DatabasesController#create with post method. The controller parameter
  #   of the request is set to admin/databases and setting the
  #   database parameter to a hash containing the name of the database.
  #   The session variable user is set to the user with an account limit. 
  #   Afterwards, we again get the database count.
  #   We excpet the following:
  #     * The responce is success.
  #     * The difference between post an pre database counts is 0
  #     * The DatabasesController#database error count is 1
  #
  def test_create_with_correct_user_but_limit_of_account_reached
    pre_databases_count = Database.count
    post :create, {"controller"=>"admin/databases", "database"=>{"name"=>"hjhj"}}, { 'user' => User.find_by_id(@db2_admin_user_id)}
    post_databases_count = Database.count

    #redirected to db list
    assert_response :success
    #one db created
    assert_equal 0, post_databases_count - pre_databases_count
    #one error on the database
    assert_equal 1, assigns["database"].errors.count
    
    
  end

  # *Description*
  #   We chekc the DatabasesController#edit action with a correct user.
  #   
  # *Strategy*
  #   We call the GET method on DatabasesController#edit where paramerts include
  #   database id and the session variable user is also set.
  #   We expect following:
  #     * Response is success
  #     * Rendered template is edit.erb
  #     * The response contains the tag <input>
  #     * The @database is valid after editing.
  #
  def test_edit
    get :edit, {'id' => 6} , { 'user' => User.find_by_id(@db1_admin_user_id)}
    assert_response :success
    assert_template 'edit'
    assert_tag :tag => "input",:attributes =>{ :type => "text", :name => "database[name]", :value => "demo_forem"}
    assert(assigns('database').valid?)
  end

  # *Description*
  #   We check the DatabasesController#update method by invoking it through POST
  #   
  # *Strategy*
  #   We check the current databse count.
  #   The we invoke the DatabasesController#update with POST method where
  #   parameters include:
  #     * commit      => Edit
  #     * action      => update
  #     * id          => 6
  #     * controller  => admin/databases
  #     * database    => demo_form_updated.
  #   Afterwards, we seek the database count.
  #   We expect the following:
  #     * responce is to redirect
  #     * We are redirected to the action DatabasesController#list
  #     * The name of the database has been changed.
  #     * The datbase count is the same as before the POST
  #
  def test_update
    pre_databases_count = Database.count
    post :update, {"commit"=>"Edit", "action"=>"update", "id"=>"6", "controller"=>"admin/databases", "database"=>{"name"=>"demo_forem_updated"}} , { 'user' => User.find_by_id(@db1_admin_user_id)}
    post_databases_count = Database.count
    #redirect to list of DBs after update
    assert_response :redirect
    assert_redirected_to :action => "list"
    #db name has been updated
    db = Database.find 6
    assert_equal "demo_forem_updated", db.name
    #no db has been created
    assert_equal pre_databases_count, post_databases_count
  end

  # *Description*
  #   Here we test to delete a database.
  # 
  # *Strategy*
  #   We obtain the count of databases, entities and detail_values. Then we 
  #   invoke the DatabasesController#destroy by POST. id is the parameter and
  #   session variable user is also set.
  #   We again obtain the count of databases, entiteisa and detail_values 
  #   after deletion.
  #   We expect the following:
  #     * response is to redirect
  #     * We are redirected to DatabasesController#list
  #     * Obtaining the databases deleted raises exception.
  #     * The database, entities and detail_value counts are decremented.
  #   
  #
  def test_destroy
    assert_not_nil Database.find(6)

    pre_databases_count = Database.count
    pre_entities_count = Entity.count
    pre_detail_values_count = DetailValue.count
    post :destroy, {'id' => 6}, { 'user' => User.find_by_id(@db1_admin_user_id)}
    post_databases_count = Database.count
    post_entities_count = Entity.count
    post_detail_values_count = DetailValue.count

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      database = Database.find(6)
    }
    
    assert_equal -1, post_databases_count-pre_databases_count
    assert_equal -14, post_entities_count-pre_entities_count
    assert_equal -204, post_detail_values_count-pre_detail_values_count
  end

end

