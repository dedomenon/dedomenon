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
require 'authentication_controller'

# Raise errors beyond the default web-based presentation
class AuthenticationController; def rescue_action(e) raise e end; end

class AuthenticationControllerTest < ActionController::TestCase
  
  fixtures :account_types, :accounts,:user_types, :users
  
  def setup
    @controller = AuthenticationController.new
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
    @request.host = "localhost"
  end
  
  def test_auth_bob
    @request.session['return-to'] = @controller.url_for("/bogus/location")

    post :login, "user" => { "login" => "bob", "password" => "atest" }
		
    assert(@response.has_session_object?( "user"))

    bob = User.find  1000001
    assert_equal bob, @response.session["user"]
    
    assert_response :redirect
    assert_redirected_to "/bogus/location"
  end

  def test_login_cancelled_account
#    @request.session['return-to'] = @controller.url_for("/bogus/location")


    #First test with account to be cancelled next week
    account = Account.find 5
    account.end_date = Time.now.next_week
    account.save
    post :login, "user" => { "login" => "fbasicc1@example.com", "password" => "atest" }
    assert(@response.has_session_object?( "user"))
    
    u = User.find 1000010
    assert_equal u, @response.session["user"]
    
    assert_response :redirect
    assert_redirected_to :controller => "database"
    
    #Then test with account to cancelled last month
    account = Account.find 5
    account.end_date = Time.now.last_month
    account.save
    post :login, "user" => { "login" => "fbasicc1@example.com", "password" => "atest" }
		
    assert(@response.has_session_object?( "user"))

    u = User.find 1000010
    assert_equal 1, u.verified
    assert_equal u, @response.session["user"]
    
    assert_response :success
    assert_equal assigns["message"], "madb_account_not_active_or_cancelled" 
  end


  def test_login_account_expired
    post :login, "user" => { "login" => "fbasice1@example.com", "password" => "atest" }
		
    assert(@response.has_session_object?( "user"))

		u = User.find 1000011
    assert_equal 1, u.verified
    assert_equal u, @response.session["user"]
    assert_equal "expired", u.account.status
    
    assert_response :redirect
    assert_redirected_to :controller => "payments", :action => "reactivate"
  end


  def test_auth_inexisting_user
    @request.session['return-to'] = @controller.url_for("/bogus/location")

    post :login, "user" => { "login" => "fzhlmzivsnc", "password" => "atest" }
		
    assert(!@response.has_session_object?( "user"))

    assert_response :success
  end
  
	#incorrect
	#---------
  def test_signup_with_no_company
    pre_accounts_count = Account.count
    pre_users_count = User.count
    post :signup ,{"user"=>{  "login"=>"raphinou2new@yahoo.com", 
                              "login_confirmation"=>"raphinou2new@yahoo.com",
                              "password"=>"raphinou", 
                              "password_confirmation"=>"raphinou"
                            }, 
                            "commit"=>"Signup", 
                            "account"=>{
                              "city"=>"", 
                              "name"=>"", 
                              "country"=>"0", 
                              "zip_code"=>"", 
                              "street"=>""}, 
                            "action"=>"signup", 
                            "controller"=>"authentication", 
                            "account_type_id" => "1",
                            "tos_accepted" => "on"
                            
                   }
    post_accounts_count = Account.count
    post_users_count = User.count


    #no user in session
    assert(!@response.has_session_object?( "user"))
    #we can't find the user created
    user = User.find_by_login("raphinou2new")
    assert_nil user
    #no account created
    assert_equal post_accounts_count, pre_accounts_count
    #no user created
    assert_equal post_users_count, post_users_count
    #we render the signup form
    assert_template "signup"
    #2 errors on account: name and country
    assert_equal 2, assigns["account"].errors.count
    assert_not_nil(assigns["account"].errors.on( "name"))
    assert_not_nil(assigns["account"].errors.on( "country"))
     #1 error on user: the account is invalid	
     # NOTE: Again this tests fails because there are duplicate errors
    assert_equal 2, assigns["user"].errors.count
    assert_not_nil(assigns["user"].errors.on("account"))
  end




	#existing user
  def test_signup_with_existing_user_and_password_too_short
    pre_accounts_count = Account.count
    pre_users_count = User.count
     post :signup, {"user"=>{"password_confirmation"=>"test", 
                    "login"=>"bob", "password"=>"test"}, 
                    "commit"=>"Signup", 
                    "account"=> {
                              "city"=>"", 
                              "name"=>"test company", 
                              "country"=>"Belgium", 
                              "zip_code"=>"", 
                              "street"=>""
                              }, 
                              "action"=>"signup", 
                              "controller"=>"authentication", 
                              "account_type_id" => "1", 
                              "tos_accepted" => "on"
                              
                              }
    post_accounts_count = Account.count
    post_users_count = User.count


		#no user in session
    assert(!@response.has_session_object?( "user"))
		#we can't find the user created
    user = User.find_by_login("raphinou2new")
    assert_nil user
		#no account created
    assert_equal post_accounts_count, pre_accounts_count
    #no user created
    assert_equal post_users_count, post_users_count
    #we render the signup form
    assert_template "signup"
    #0 errors on account: name and country
    assert_equal 0, assigns["account"].errors.count
     #5 error on user: the login exists
     # NOTE: Same problem here, duplicate error objects
    assert_equal 10, assigns["user"].errors.count
    #login invalid and already taken
    assert_not_nil(assigns["user"].errors.on( "login"))
    assert_not_nil(assigns["user"].errors.on( "login_confirmation"))
    assert_not_nil(assigns["user"].errors.on( "password"))
  end






  def test_signup_with_existing_user_and_password_too_short2
    pre_accounts_count = Account.count
    pre_users_count = User.count
    post :signup, {"user" =>
                            {
                              "password_confirmation" =>  "t", 
                              "login"=>"test@test.com", 
                              "login_confirmation"=>"test@test.com", 
                              "password"=>"t"
                            }, 
                  "commit"=>"Signup", 
                  "account" =>  {
                                  "city"  =>  "", "name"=>"test company", 
                                  "country" =>  "Belgium", 
                                  "zip_code"=>"", 
                                  "street"=>""
                                }, 
                  "action"  =>  "signup", 
                  "controller"  =>"authentication", 
                  "account_type_id" => "1", 
                  "tos_accepted" => "on"
                 
                 }
    
    post_accounts_count = Account.count
    post_users_count = User.count


        
    
    
    #no user in session
    assert(!@response.has_session_object?( "user"))
    #we can't find the user created
    user = User.find_by_login("raphinou2new")
    assert_nil user
    #no account created
    assert_equal post_accounts_count, pre_accounts_count
    #no user created
    assert_equal post_users_count, post_users_count
    #we render the signup form
    assert_template "signup"
    #2 errors on account: name and country
    assert_equal 0, assigns["account"].errors.count
     #1 error on user: the login exists
     # NOTE: This has to be changed to two because the errors colelction contains
     # two duplicate errors of madb_password_too_short.
    assert_equal( 2, assigns["user"].errors.count)
    assert_not_nil(assigns["user"].errors.on( "password"))
  end
	#success:
	#{"user"=>{"password_confirmation"=>"taphinou", "login"=>"raphinou-test", "password"=>"taphinou", "email"=>"rb@raphinou.com"}, "commit"=>"Signup", "account"=>{"city"=>"", "name"=>"test company", "country"=>"Belgium", "zip_code"=>"", "street"=>""}, "action"=>"signup", "controller"=>"authentication"}
	#
  def test_signup
    ActionMailer::Base.deliveries = []
    @request.session['return-to'] = "/bogus/location"

    #post :signup, "user" => { "login" => "newbob", "password" => "newpassword", "password_confirmation" => "newpassword", "email" => "newbob@test.com" }
		post :signup, {"user"=>{ "login"=>"rb-signup@raphinou.com", "login_confirmation"=>"rb-signup@raphinou.com", "password"=>"taphinou", "password_confirmation" => "taphinou", "firstname" => "raphaël", "lastname" => "bauduin"}, "commit"=>"Signup", "account"=>{"city"=>"", "name"=>"test company", "country"=>"Belgium", "zip_code"=>"", "street"=>""}, "action"=>"signup", "controller"=>"authentication", :account_type_id => "1", "tos_accepted" => "on"}
    assert(!@response.has_session_object?( "user"))
    
		assert_response :redirect
    assert_equal 1, ActionMailer::Base.deliveries.size
    mail = ActionMailer::Base.deliveries[0]
    assert_equal "rb-signup@raphinou.com", mail.to_addrs[0].to_s
    assert_match /login:\s+rb-signup@raphinou.com\n/, mail.encoded
    assert_no_match /password:\s+\w+\n/, mail.encoded
    assert_match Regexp.new("http://\\w+(/\\w+)*/authentication/verify/\\w+"), mail.encoded

    user = User.find_by_login("rb-signup@raphinou.com")
    assert_not_nil user
    assert_equal 0, user.verified
    post :verify, "id" => user.uuid.to_s
    user = User.find_by_login("rb-signup@raphinou.com")
    assert_equal 1, user.verified
    assert_redirected_to(@controller.url_for(:action => "login"))
    #user created at signup is primary user
    assert_equal 1, user.user_type_id
    assert_equal "raphaël", user.firstname
    assert_equal "bauduin", user.lastname
  end





  def test_signup_basic
    ActionMailer::Base.deliveries = []
    @request.session['return-to'] = "/bogus/location"

    #post :signup, "user" => { "login" => "newbob", "password" => "newpassword", "password_confirmation" => "newpassword", "email" => "newbob@test.com" }
		post :signup, {"user"=>{ "login"=>"rb-signup@raphinou.com", "login_confirmation"=>"rb-signup@raphinou.com", "password"=>"taphinou", "password_confirmation" => "taphinou", "firstname" => "raphaël", "lastname" => "bauduin"}, "commit"=>"Signup", "account"=>{"city"=>"", "name"=>"test company", "country"=>"Belgium", "zip_code"=>"", "street"=>""}, "action"=>"signup", "controller"=>"authentication", :account_type_id => "2", "tos_accepted" => "on"}

    #user is in session, but account still inactive
    assert_not_nil  session["user"]
    assert_equal "inactive", session["user"].account.status
    
		assert_response :redirect
    assert_redirected_to :controller => "payments", :action => "complete"
    assert_equal 0, ActionMailer::Base.deliveries.size

    user = User.find_by_login("rb-signup@raphinou.com")
    assert_not_nil user

    #user not yet verified. Will be verified when payment is confirmed
    assert_equal 0, user.verified
    post :verify, "id" => user.uuid.to_s
    user = User.find_by_login("rb-signup@raphinou.com")
    assert_equal 1, user.verified
    assert_redirected_to(@controller.url_for(:action => "login"))
    #user created at signup is primary user
    assert_equal 1, user.user_type_id
    assert_equal "raphaël", user.firstname
    assert_equal "bauduin", user.lastname
  end






  def test_verify_with_incorrect_string
    get :verify, { :id => "hlhljk" }, {}
    assert_response :redirect
    assert_equal flash["message"], "madb_account_activation_impossible_because_not_found"
    assert flash["notice"].nil?
  end

  def test_signup_without_tos
    ActionMailer::Base.deliveries = []
    @request.session['return-to'] = "/bogus/location"

		post :signup, {"user"=>{ "login"=>"rb-signup@raphinou.com", "login_confirmation"=>"rb-signup@raphinou.com", "password"=>"taphinou", "password_confirmation" => "taphinou", "firstname" => "raphaël", "lastname" => "bauduin"}, "commit"=>"Signup", "account"=>{"city"=>"", "name"=>"test company", "country"=>"Belgium", "zip_code"=>"", "street"=>""}, "action"=>"signup", "controller"=>"authentication", :account_type_id => "1"}
    assert(!@response.has_session_object?( "user"))
    
		assert_response :success
    assert_equal 0, ActionMailer::Base.deliveries.size

    user = User.find_by_login("rb-signup@raphinou.com")
    assert_nil user
  end


  def do_change_password(bad)
    ActionMailer::Base.deliveries = []

    post :login, "user" => { "login" => "bob", "password" => "atest" }
    assert(@response.has_session_object?( "user"))

    @request.session['return-to'] = "/bogus/location"
    if not bad
      post :change_password, "user" => { "password" => "changed_password", "password_confirmation" => "changed_password" }
      assert_equal 0, ActionMailer::Base.deliveries.size

			assert_response :redirect
      assert_redirected_to "bogus/location"
    else
      post :change_password, "user" => { "password" => "bad", "password_confirmation" => "bad" }
      assert(@response.template_objects["user"].errors.invalid?("password"))
      assert_response :success
      assert_equal 0, ActionMailer::Base.deliveries.size
    end

    get :logout
    assert(!@response.has_session_object?( "user"))

    if not bad
      post :login, "user" => { "login" => "bob", "password" => "changed_password" }
      assert(@response.has_session_object?( "user"))
      post :change_password, "user" => { "password" => "atest", "password_confirmation" => "atest" }
    else
      post :login, "user" => { "login" => "bob", "password" => "atest" }
      assert(@response.has_session_object?( "user"))
    end

    get :logout
  end

  def test_change_password
    do_change_password(false)
    do_change_password(true)
  end

  def do_forgot_password(bad, logged_in)
    ActionMailer::Base.deliveries = []

    if logged_in
      post :login, "user" => { "login" => "bob", "password" => "atest" }
      assert(@response.has_session_object?( "user"))
    end

    @request.session['return-to'] = "/bogus/location"
    if bad
      post :forgot_password, "user" => { "email" => "bademail@test.com" }
      assert_equal 0, ActionMailer::Base.deliveries.size
      assert(@response.has_flash_object?("message"))
    else
      post :forgot_password, "user" => { "email" => "bob@test.com" }
      assert_equal 1, ActionMailer::Base.deliveries.size
      mail = ActionMailer::Base.deliveries[0]
      assert_equal "bob@test.com", mail.to_addrs[0].to_s
      assert_match /madb_login:\s+bob@test.com/, mail.encoded
      assert_match /madb_password:\s+\w{8}/, mail.encoded
      mail.encoded =~ /madb_password:\s+(\w{8})\n/
      #the hos used by this call to url_for is localhost, and not test.host. Don't know why....
      assert_match Regexp.new("http://localhost/app"), mail.encoded
      password = $1
    end

    if logged_in
			assert_response :redirect
      assert_redirected_to "bogus/location"
    else
      if not bad
        assert_redirected_to("/app")
        post :login, "user" => { "login" => "bob", "password" => "#{password}" }
      end
    end

    if not bad
      post :change_password, "user" => { "password" => "atest", "password_confirmation" => "atest" }
      #assert_response :redirect
      get :logout
    end
  end

  # FIXME: Middle case fails due to session containing whole user object
  def test_forgot_password
    do_forgot_password(false, false)
    do_forgot_password(false, true)
    do_forgot_password(true, false)
  end

  def test_bad_signup
    @request.session['return-to'] = "/bogus/location"

    post :signup, {"user" => { "login" => "newbob", "password" => "newpassword", "password_confirmation" => "wrong" }, "tos_accepted" => "on"}
    assert(@response.template_objects["user"].errors.invalid?("password"))
    assert_response :success
    
    post :signup, {"user" => { "login" => "yo", "password" => "newpassword", "password_confirmation" => "newpassword" }, "tos_accepted" => "on"}
    assert(@response.template_objects["user"].errors.invalid?("login"))
    assert_response :success

    post :signup, {"user" => { "login" => "yo", "password" => "newpassword", "password_confirmation" => "wrong" }, "tos_accepted" => "on"}
    assert(@response.template_objects["user"].errors.invalid?("login"))
    assert(@response.template_objects["user"].errors.invalid?("password"))
    assert_response :success
  end

  def test_invalid_login
    post :login, "user" => { "login" => "bob", "password" => "not_correct" }
     
    assert(!@response.has_session_object?( "user"))
    
    assert_not_nil  assigns["message"]
    assert(@response.has_template_object?("login"))
  end
  
  def test_login_logoff

    post :login, "user" => { "login" => "bob", "password" => "atest" }
    assert(@response.has_session_object?( "user"))

    get :logout
    assert(!@response.has_session_object?( "user"))

  end

  def test_login_expired_account
    post :login, "user" => { "login" => "fbasice1@example.com", "password" => "atest" }
    assert_response :redirect

    assert_redirected_to :controller => "payments", :action => "reactivate"

  end

  def test_login_invalid_status_account
    ActionMailer::Base.deliveries = []
    account = Account.find(6)
    account.status = 'invalid_status'
    account.save
    post :login, "user" => { "login" => "fbasice1@example.com", "password" => "atest" }
    assert_response :success

    assert_equal 1, ActionMailer::Base.deliveries.size
    mail = ActionMailer::Base.deliveries[0]
    assert_equal AppConfig.exception_recipients.to_s, mail.header["to"].to_s
    assert_equal "[AUTHENTICATION ERROR] for fbasice1@example.com", mail.header["subject"].to_s
    assert_match %r{Authentication for fbasice1@example.com \(with verified = 1\) of account 6 \(with status = invalid_status\) was refused}, mail.encoded

  end
  
end
