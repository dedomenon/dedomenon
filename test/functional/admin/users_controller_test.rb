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
require 'admin/users_controller'

# Re-raise errors caught by the controller.
class Admin::UsersController; def rescue_action(e) raise e end; end

class Admin::UsersControllerTest < ActionController::TestCase

  fixtures  :account_types,
            :accounts, 
            :account_type_values,
            
            :databases, 
            :data_types, 
            :detail_status, 
            
            :details, 
            :detail_value_propositions, 
            
            :entities, 
            :entities2details, 
            :relation_side_types, 
            :relations, 
            :instances, 
            :detail_values, 
            :integer_detail_values, 
            :date_detail_values, 
            :ddl_detail_values, 
            :links, 
            :user_types, :users
  
  # *Description*
  #   Sets up objects for testing, a new controller, request and response.
  #
  def setup
    @controller = Admin::UsersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @db1_admin_user_id = 2
    @db2_admin_user_id = 1000003
  end
  
   
  # *Description*
  #   Here we check whether we are able to access the index page when we 
  #   have correct user rights?
  # 
  # *Strategy*
  #   We hit the index while setting the session variables user and account_id
  #   We expect the following:
  #     * Response is succuss
  #     * Number of users is correct.
  #     * Tags to delete and reset passwords are available.
  #  
  def test_index_correct_user
    get :index, {},  { 'user' => User.find_by_id(@db1_admin_user_id), 'account_id' => 1}
    #we redirect to login form
    #succes?
    assert_response :success
    #correct number of users?
    assert_equal 5, assigns["users"].length
    #admin users
    admin_users = assigns["users"].select{|u| u.user_type_id==2}
    assert 2, admin_users.length
    assert 2, admin_users[0].id
    #delete for normal users
    assert_tag :tag => "a", :attributes => { :href=> Regexp.new("/admin/users/destroy/1000001")}
    assert_tag :tag => "a", :attributes => { :href=> Regexp.new("/admin/users/destroy/1000002")}
    #no delete for primary user
    assert_no_tag :tag => "a", :attributes => { :href=> Regexp.new("/admin/users/destroy/2")}
    
    #reset password links
    assert_tag :tag => "a", :attributes => { :href=> Regexp.new("/admin/users/reset_password/1000001")}
    assert_tag :tag => "a", :attributes => { :href=> Regexp.new("/admin/users/reset_password/1000002")}
    assert_tag :tag => "a", :attributes => { :href=> Regexp.new("/admin/users/reset_password/2")}
    #no show links
    assert_no_tag :tag => "a", :attributes => { :href=> Regexp.new("/admin/users/show/1000001")}
    assert_no_tag :tag => "a", :attributes => { :href=> Regexp.new("/admin/users/show/1000002")}
    assert_no_tag :tag => "a", :attributes => { :href=> Regexp.new("/admin/users/show/2")}

    #new user link
    assert_tag :tag => "a", :attributes => { :href=> Regexp.new("/admin/users/new")}
  end

  # *Description*
  #   We check whether we can aceess the index page while beinga a wrong user.
  # 
  # *Strategy*
  #   We hit the index page with wrong user user.
  #   We expect to be redirected.
  def test_index_wrong_user
    get :index, {},  { 'user' => User.find_by_id(1000002)}
    #we redirect to login form
    #redirection?
    assert_response :redirect
    #assert_redirected_to :controller => "/database"
  end

  # *Description*
  #   We reset password of a user.
  #   
  # *Strategy*
  #   We hit the UsersController#rest_password using POST method while the 
  #   params contain id of the user and session variable user to that user
  #   We expect following
  #     * Redirection to list
  #     * A flash notice
  #     * Mail is sent
  #     * password is changed.
  #
  def test_reset_password
    ActionMailer::Base.deliveries = []
    pre_user = User.find 1000002
    post :reset_password, {:id => "1000002"},  { 'user' => User.find_by_id(@db1_admin_user_id)}
    post_user = User.find 1000002
    #redirect to list?
    assert_response :redirect
    assert_redirected_to :action => "list"

    #correct notice?
    assert_equal "madb_password_reset_mail_sent", flash["notice"]

    #mail sent with info?
    assert_equal 1, ActionMailer::Base.deliveries.size
    mail =  ActionMailer::Base.deliveries[0]
    assert_match /madb_login:\s+existingbob@test.com/, mail.encoded
    assert_match Regexp.new("madb_password:\s+#{assigns["newpass"]}"), mail.encoded
    
    #check correct link is in the mail
    assert_match /http:\/\/test.host\/app/, mail.encoded

    #check pass has changed
    assert_not_equal pre_user.password, post_user.password
    assert_equal pre_user.verified, post_user.verified

  end

  ############
  #edit
  ############
  #redirect to list for the time being
  
  # *Description*
  #   We try to hit UsersController#edit action
  #   
  def test_edit
    get :edit, {:id => "1000002"},  { 'user' => User.find_by_id(@db1_admin_user_id)}
    assert_response :success
    assert_template "edit"
  end

  # *Description*
  # Testing the update procedure
  def test_update

    # It was sending the user information in the params[:users] but its now 
    # changed to params[:user]
    post :update, {"commit"=>"Edit", "id"=>"1000001", "user"=>{"firstname"=>"Bob", "lastname"=>"Bark", "login"=>"bob@test.com", "user_type_id" => "1"}}, { 'user' => User.find_by_id(@db1_admin_user_id)}
    user = User.find 1000001
    #correct response?
    assert_response :redirect
    assert_redirected_to :action => "show", :id => 1000001
    
    #user updated?
    assert_equal "Bob", user.firstname
    assert_equal "Bark", user.lastname
    assert_equal "bob@test.com", user.login
    assert_equal "bob@test.com", user.email
    assert_equal 1, user.user_type_id
  end

  def test_update_with_existing_login

    #Currently, the email address of a user cannot be updated.
    #When the email address of a user can be changed, this test has to be adapted.
    post :update, {"commit"=>"Edit", "id"=>"1000001", "user"=>{"firstname"=>"Bob", "lastname"=>"Bark", "login"=>"bob@test.com", "user_type_id" => "1"}}, { 'user' => User.find_by_id(@db1_admin_user_id)}
    user = User.find 1000001
    #correct response?
    assert_response :redirect
    assert_redirected_to :action => "show", :id => 1000001
    
    #user updated?
    assert_equal "Bob", user.firstname
    assert_equal "Bark", user.lastname
    assert_equal "bob@test.com", user.login
    assert_equal "bob@test.com", user.email
    assert_equal 1, user.user_type_id

    assert_equal 0, assigns["users"].errors.count
  end
  
  def test_new
    get :new, {},  { 'user' => User.find_by_id(@db1_admin_user_id)}
    assert_response :success
  end

  def test_create
    ActionMailer::Base.deliveries = []
    pre_users_count = User.count
  post :create,  {"user"=>{"user_type_id"=>"2", "lastname"=>"raph", "firstname"=>"baud", "login"=>"login@yahoo.com", "login_confirmation"=>"login@yahoo.com"}, "commit"=>"Signup"}, { 'user' => User.find_by_id(@db1_admin_user_id)}
    post_users_count = User.count

    
    #correct_redirection
    assert_response :redirect
    assert_redirected_to :action => "list"
    #user created and mail delivered?
    assert_equal 1, post_users_count-pre_users_count
    assert_equal 1, ActionMailer::Base.deliveries.size
    #mail content ok?
    mail =  ActionMailer::Base.deliveries[0]
    assert_match /madb_login:\s+login@yahoo.com/, mail.encoded
    assert_match Regexp.new("madb_password:\s+#{assigns["newpass"]}"), mail.encoded
    assert_match /http:\/\/test.host\/app/, mail.encoded

    user = User.find :first, :order => "id DESC"
    assert_equal "login@yahoo.com", user.login
    assert_equal "login@yahoo.com", user.email
    assert_equal 1, user.account_id
  end



  def test_create_no_login_confirmation
    ActionMailer::Base.deliveries = []
    pre_users_count = User.count
    post :create,  {"user"=>{"user_type_id"=>"2", "lastname"=>"raph", "firstname"=>"baud", "login"=>"login@yahoo.com"}, "commit"=>"Signup"}, { 'user' => User.find_by_id(@db1_admin_user_id)}
    post_users_count = User.count

    
    #correct page displayed
    assert_response :success
    assert_template "new"
    #user created and mail delivered?
    assert_equal 0, post_users_count-pre_users_count
    assert_equal 0, ActionMailer::Base.deliveries.size
  end

  def test_create_login_not_email
    ActionMailer::Base.deliveries = []
    pre_users_count = User.count
  post :create,  {"user"=>{"user_type_id"=>"2", "lastname"=>"raph", "firstname"=>"baud", "login"=>"login", "login_confirmation" => "login"}, "commit"=>"Signup"}, { 'user' => User.find_by_id(@db1_admin_user_id)}
    post_users_count = User.count

    
    #correct page displayed
    assert_response :success
    assert_template "new"
    #user created and mail delivered?
    assert_equal 0, post_users_count-pre_users_count
    assert_equal 0, ActionMailer::Base.deliveries.size
  end




  def test_destroy
    pre_users_count = User.count
    post :destroy, {:id => 1000001}, { 'user' => User.find_by_id(@db1_admin_user_id)}
    post_users_count = User.count

    #correct redirection?
    assert_response :redirect
    assert_redirected_to :action => "list"

    #one user removed?
    assert_equal -1, post_users_count-pre_users_count
    assert_raises(ActiveRecord::RecordNotFound){  User.find(1000001) }
  end

  def test_destroy_admin_user
    pre_users_count = User.count
    post :destroy, {:id => 1000006}, { 'user' => User.find_by_id(@db1_admin_user_id)}
    post_users_count = User.count

    #correct redirection?
    assert_response :redirect
    assert_redirected_to :action => "list"

    #no user removed as it is a primary user?
    assert_equal 0, post_users_count-pre_users_count
    assert_not_nil User.find(1000006) 
  end

  def test_destroy_user_other_account
    pre_users_count = User.count
    post :destroy, {:id => 1000003}, { 'user' => User.find_by_id(@db1_admin_user_id)}
    post_users_count = User.count

    #correct redirection?
    assert_response :redirect
    assert_redirected_to :action => "list"

    #no user removed as it is a primary user?
    assert_equal 0, post_users_count-pre_users_count
    assert_not_nil User.find(1000003) 
  end
end
