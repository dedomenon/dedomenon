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
require 'admin/details_controller'

# Re-raise errors caught by the controller.
class Admin::DetailsController; def rescue_action(e) raise e end; end

class Admin::DetailsControllerTest < ActionController::TestCase
  fixtures  :accounts,
            :databases,
            :user_types, 
            :users, 
            :entities, 
            :data_types, 
            :detail_status, 
            :details, 
            :instances, 
            :detail_values
          

  def setup
    @controller = Admin::DetailsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @db1_admin_user_id = 2
    @db2_admin_user_id = 1000003
  end

  def test_new_detail_for_entity
    #----------------------------
    get :new, {'for_entity'=>11},   { 'user' => User.find_by_id(@db1_admin_user_id), 'return-to' => @controller.url_for('/admin/details/list')}
    assert_response :success
  end

  def test_create_short_text_detail_for_entity
    #-----------------------------------------
    pre_details_count = Detail.count
    #pre_details_count_in_db = Detail.count("database_id=6")
    pre_details_count_in_db = Detail.count(:conditions => "database_id=6")
    post :create, {"details"=>{"name"=>"test_short_text", "data_type_id"=>"1"},:null => "", "for_entity"=>"11"},{ 'user' => User.find_by_id(@db1_admin_user_id), 'return-to' => @controller.url_for('admin/details/new')}
    post_details_count = Detail.count
    post_details_count_in_db = Detail.count(:conditions => "database_id=6")


    #redirect?
    assert_response :redirect
    assert_redirected_to :controller => "admin/entities", :action => "add_existing_precisions", :id => "11", :detail_id => 104
    
    #One detail added?
    assert_equal 1, post_details_count_in_db-pre_details_count_in_db
    assert_equal 1, post_details_count-pre_details_count

    detail = Detail.find :first, :order => "id DESC" 
    assert_equal "test_short_text", detail.name
    assert_equal 6 , detail.database_id
    assert_equal 1 , detail.data_type_id
  end


  def test_create_short_text_detail_for_entity_existing_name
    #-----------------------------------------
    pre_details_count = Detail.count
    pre_details_count_in_db = Detail.count(:conditions => "database_id=6")
    post :create, {"details"=>{"name"=>"memo", "data_type_id"=>"1"},:null => "", "for_entity"=>"11"},
      { 
      'user' => User.find_by_id(@db1_admin_user_id),
      'return-to' => @controller.url_for('admin/details/new')
      
      }
    post_details_count = Detail.count
    post_details_count_in_db = Detail.count(:conditions => "database_id=6")


    #redirect?
    assert_response :success
    
    #No detail added?
    assert_equal 0, post_details_count_in_db-pre_details_count_in_db
    assert_equal 0, post_details_count-pre_details_count

  end

  def test_create_short_text_detail_for_entity_empty_name
    #-----------------------------------------
    pre_details_count = Detail.count
    pre_details_count_in_db = Detail.count(:conditions => "database_id=6")
    post :create, {"details"=>{"name"=>"", "data_type_id"=>"1"},:null => "", "for_entity"=>"11"},
      { 'user' => User.find_by_id(@db1_admin_user_id),
        'return-to' => @controller.url_for('admin/details/new')
      }
    post_details_count = Detail.count
    post_details_count_in_db = Detail.count(:conditions => "database_id=6")


    #redirect?
    assert_response :success
    
    #No detail added?
    assert_equal 0, post_details_count_in_db-pre_details_count_in_db
    assert_equal 0, post_details_count-pre_details_count

  end

  def test_create_short_text_detail_for_entity_id_name
    #-----------------------------------------
    pre_details_count = Detail.count
    pre_details_count_in_db = Detail.count(:conditions => "database_id=6")
    post :create, {"details"=>{"name"=>"id", "data_type_id"=>"1"},:null => "", "for_entity"=>"11"},
      { 'user' => User.find_by_id(@db1_admin_user_id),
        'return-to' => @controller.url_for('admin/details/new')
      
      }
    post_details_count = Detail.count
    post_details_count_in_db = Detail.count(:conditions => "database_id=6")


    #redirect?
    assert_response :success
    
    #No detail added?
    assert_equal 0, post_details_count_in_db-pre_details_count_in_db
    assert_equal 0, post_details_count-pre_details_count

    pre_details_count = Detail.count
    pre_details_count_in_db = Detail.count(:conditions => "database_id=6")
    post :create, {"details"=>{"name"=>"ID", "data_type_id"=>"1"},:null => "", "for_entity"=>"11"},{ 'user' => User.find_by_id(@db1_admin_user_id)}
    post_details_count = Detail.count
    post_details_count_in_db = Detail.count(:conditions => "database_id=6")


    #redirect?
    assert_response :success
    
    #No detail added?
    assert_equal 0, post_details_count_in_db-pre_details_count_in_db
    assert_equal 0, post_details_count-pre_details_count
  end


  def test_create_short_text_detail_for_entity_quick_commit
    #------------------------------------------------------
    pre_details_count = Detail.count
    pre_details_count_in_db = Detail.count(:conditions => "database_id=6")
    entity = Entity.find 11
    pre_entity_details = entity.details.length
    post :create, {"details"=>{"name"=>"test_short_text", "data_type_id"=>"1"},:null => "", "for_entity"=>"11", "quick_commit" => "quick_commit"},{ 'user' => User.find_by_id(@db1_admin_user_id)}
    post_details_count = Detail.count
    post_details_count_in_db = Detail.count(:conditions => "database_id=6")
    post_entity_details = entity.details.length
    last_detail = Detail.find(:first, :order => "id DESC")
    


    #redirect?
    assert_response :redirect
    assert_redirected_to :controller => "admin/entities", :action => "add_existing", :id => "11", :detail_id => last_detail.id,:status_id => 1, :displayed_in_list_view => true, :maximum_number_of_values => 1, :display_order =>entity.details.length*10
    
    #One detail added?
    assert_equal 1, post_details_count_in_db-pre_details_count_in_db
    assert_equal 1, post_details_count-pre_details_count
    #detail is created but not linked yet
    assert_equal 0, post_entity_details-pre_entity_details

    detail = Detail.find :first, :order => "id DESC" 
    assert_equal "test_short_text", detail.name
    assert_equal 6 , detail.database_id
    assert_equal 1 , detail.data_type_id
  end




  def test_create_short_text_detail_for_inexisting_entity
    #----------------------------------------------------
    pre_details_count = Detail.count
    pre_details_count_in_db = Detail.count(:conditions => "database_id=6")
    post :create, {"details"=>{"name"=>"test_short_text", "data_type_id"=>"1"},:null => "", "for_entity"=>"1134"},{ 'user' => User.find_by_id(@db1_admin_user_id)}
    post_details_count = Detail.count
    post_details_count_in_db = Detail.count(:conditions => "database_id=6")


    #redirect?
    assert_response :redirect
    assert_redirected_to :controller => "admin/databases"
    
    #One detail added?
    assert_equal 0, post_details_count_in_db-pre_details_count_in_db
    assert_equal 0, post_details_count-pre_details_count

    assert_equal "madb_error_incorrect_data", flash["error"]
  end



  
  def test_create_ddl_detail_for_entity
    #-----------------------------------------
    #{"propositions"=>["prop1", "prop2", "prop3", "prop4"], "commit"=>"Create", "details"=>{"name"=>"test_ddl", "data_type_id"=>"5"}, "action"=>"create", "controller"=>"admin/details", "null"=>"prop4", "for_entity"=>"11"}
    pre_details_count = Detail.count
    pre_details_count_in_db = Detail.count(:conditions => "database_id=6")
    post :create, {"propositions"=>["prop1", "prop2", "prop3", "prop4"],"details"=>{"name"=>"test_ddl", "data_type_id"=>"5"},:null => "prop4", "for_entity"=>"11"},{ 'user' => User.find_by_id(@db1_admin_user_id)}
    post_details_count = Detail.count
    post_details_count_in_db = Detail.count(:conditions => "database_id=6")


    #redirect?
    assert_response :redirect
    assert_redirected_to :controller => "admin/entities", :action => "add_existing_precisions", :id => "11", :detail_id => "101"
    
    #One detail added?
    assert_equal 1, post_details_count_in_db-pre_details_count_in_db
    assert_equal 1, post_details_count-pre_details_count

    #test detail create
    detail = Detail.find :first, :order => "id DESC" 
    assert_equal "test_ddl", detail.name
    assert_equal 6 , detail.database_id
    assert_equal 5 , detail.data_type_id
    assert_equal 4, detail.detail_value_propositions.length
  end


  def test_create_detail_for_entity_non_ddl_with_value_propositions
    #--------------------------------------------------------------
    #{"propositions"=>["prop1", "prop2", "prop3", "prop4"], "commit"=>"Create", "details"=>{"name"=>"test_ddl", "data_type_id"=>"5"}, "action"=>"create", "controller"=>"admin/details", "null"=>"prop4", "for_entity"=>"11"}
    pre_details_count = Detail.count
    pre_details_count_in_db = Detail.count(:conditions => "database_id=6")
    post :create, {"propositions"=>["prop1", "prop2", "prop3", "prop4"],"details"=>{"name"=>"test_ddl", "data_type_id"=>"1"},:null => "prop4", "for_entity"=>"11"},{ 'user' => User.find_by_id(@db1_admin_user_id)}
    post_details_count = Detail.count
    post_details_count_in_db = Detail.count(:conditions => "database_id=6")


    #redirect?
    assert_response :redirect
    assert_redirected_to :controller => "admin/entities", :action => "add_existing_precisions", :id => "11", :detail_id => "102"
    
    #One detail added?
    assert_equal 1, post_details_count_in_db-pre_details_count_in_db
    assert_equal 1, post_details_count-pre_details_count

    #test detail create
    detail = Detail.find :first, :order => "id DESC" 
    assert_equal "test_ddl", detail.name
    assert_equal 6 , detail.database_id
    assert_equal 1 , detail.data_type_id
    assert_equal 0, detail.detail_value_propositions.length
  end


  
  def test_create_detail_for_entity_wrong_user
    #-----------------------------------------
    pre_details_count = Detail.count
    pre_details_count_in_db = Detail.count(:conditions => "database_id=6")
    post :create, {"details"=>{"name"=>"test_short_text", "data_type_id"=>"1"},:null => "", "for_entity"=>"11"},{ 'user' => User.find_by_id(@db2_admin_user_id)}
    post_details_count = Detail.count
    post_details_count_in_db = Detail.count(:conditions => "database_id=6")


    #redirect?
    assert_response :redirect
    #assert_redirected_to :controller => "/database"
    
    #no detail added?
    assert_equal 0, post_details_count_in_db-pre_details_count_in_db
    assert_equal 0, post_details_count-pre_details_count

  end

  def test_create_short_text_detail_for_db
    #-------------------------------------
    pre_details_count = Detail.count
    pre_details_count_in_db = Detail.count(:conditions => "database_id=6")
    post :create, {"details"=>{"name"=>"test_short_text", "data_type_id"=>"1"},:null => "", "db"=>"6"},{ 'user' => User.find_by_id(@db1_admin_user_id)}
    post_details_count = Detail.count
    post_details_count_in_db = Detail.count(:conditions => "database_id=6")


    #redirect?
    assert_response :redirect
    #assert_redirected_to :controller => "admin/details", :action => "list", :db => "6"
    #changed for rails 1.2
    assert_redirected_to :action => "list", :db => "6"
    
    #One detail added?
    assert_equal 1, post_details_count-pre_details_count
    assert_equal 1, post_details_count_in_db-pre_details_count_in_db

    detail = Detail.find :first, :order => "id DESC" 
    assert_equal "test_short_text", detail.name
    assert_equal 6 , detail.database_id
    assert_equal 1 , detail.data_type_id
  end

  def test_index
    #------------
    get :index, {:db => 6}, { 'user' => User.find_by_id(@db1_admin_user_id)}
    #success?
    assert_response :success
    #correct_number_of_details?
    assert_equal 27, assigns["details"].length
    #all details from db with id 6?
    database_ids = assigns["details"].collect{|d| d.database_id.to_i}.uniq
    assert_equal 1, database_ids.length
    assert_equal 6,database_ids[0]
    
  end

  def test_index_without_db_param
    #-----------------------------
    get :index, {}, { 'user' => User.find_by_id(@db1_admin_user_id)}
    #success?
    assert_response :redirect
    assert_redirected_to :controller => "admin/databases"

    #error message
    assert_equal "madb_error_incorrect_data", flash["error"]
  end

  def test_index_with_incorrect_db_param
    #-----------------------------------
    get :index, {:db => 24546}, { 'user' => User.find_by_id(@db1_admin_user_id)}
    #success?
    assert_response :redirect
    assert_redirected_to :controller => "admin/databases"

    #error message
    assert_equal "madb_error_incorrect_data", flash["error"]
  end



  def test_new_with_db
    get :new, {:db => 6}, 
      { 
      'user' => User.find_by_id(@db1_admin_user_id),
      'return-to'       => @controller.url_for('admin/details/new')
      }
    assert_response :success 
  end
  def test_new_without_db
    get :new, {}, { 'user' => User.find_by_id(@db1_admin_user_id)}
    assert_response :redirect
    assert_redirected_to :controller=> "admin/databases"
    assert_equal "madb_error_incorrect_data", flash["error"]
  end
  def test_list
    get :list, {}, { 'user' => User.find_by_id(@db1_admin_user_id)}
    assert_response :redirect
    assert_redirected_to :controller => "admin/databases"
    assert_equal "madb_error_incorrect_data", flash["error"]
  end
  def test_list_with_db_param
    
    get :list, { :db => "6" }, { 'user' => User.find_by_id(@db1_admin_user_id)}
    #success?
    assert_response :success
    #no error message
    assert_nil flash["error"]
    #number of details displayed
    assert_equal 27, assigns["details"].length
    # db_id of details
    db_ids=assigns["details"].collect{|d| d.database_id}.uniq
    assert_equal 1,db_ids.length
    assert_equal 6, db_ids[0].to_i

    #links for each detail
    assigns["details"].each do |d|
      assert_tag :tag => "a", :attributes => { :href => Regexp.new("/admin/details/show/#{d.id}") }
      assert_tag :tag => "a", :attributes => { :href => Regexp.new("/admin/details/edit/#{d.id}") }
      assert_tag :tag => "a", :attributes => { :href => Regexp.new("/admin/details/destroy/#{d.id}") }
    end
    
  end

  #must use fixtures because the triggers' actions are apparently not reverted with the rollback (detail_values are deleted and not restored with the rollback)
  
  def test_delete_detail

      pre_detail_values_count = DetailValue.count
      pre_detail_51_values_count = DetailValue.count(:conditions => "detail_id=52")
      pre_details_db_count = Detail.count(:conditions => "database_id=6")
      pre_details_count = Detail.count
      @request.env["HTTP_REFERER"]=@controller.url_for('/admin/details/list')

      post :destroy, { :id => 52 }, { 'user' => User.find_by_id(@db1_admin_user_id)}

      post_detail_values_count = DetailValue.count
      post_detail_51_values_count = DetailValue.count(:conditions => "detail_id=52")
      post_details_db_count = Detail.count(:conditions => "database_id=6")
      post_details_count = Detail.count

      #redirection
      assert_response :redirect
      assert_redirected_to @controller.url_for('/admin/details/list')

      #deletes 1 detail
      assert_equal 1, pre_details_count-post_details_count
      #deleted detail in correct db
      assert_equal 1, pre_details_db_count-post_details_db_count
      #removed all detail_values
      assert_equal 11, pre_detail_values_count-post_detail_values_count
      assert_equal 11, pre_detail_51_values_count-post_detail_51_values_count

      
  end


  def test_update_detail_name
    #{"commit"=>"Edit", "details"=>{"name"=>"adresse2"}, "action"=>"update", "id"=>"52", "controller"=>"admin/details", "db"=>""}
    post :update,{"commit"=>"Edit", "details"=>{"name"=>"adresse2"}, "action"=>"update", "id"=>"52", "controller"=>"admin/details", "db"=>""},{ 'user' => User.find_by_id(@db1_admin_user_id)}

    #redirect?
    assert_response :redirect
    assert_redirected_to :action => "list", :db => 6

    #updated?
    detail = Detail.find 52
    assert_equal "adresse2", detail.name
  end

  def test_update_detail_name_of_other_detail
    #{"commit"=>"Edit", "details"=>{"name"=>"adresse2"}, "action"=>"update", "id"=>"38", "controller"=>"admin/details", "db"=>""}
    post :update,{"commit"=>"Edit", "details"=>{"name"=>"adresse2"}, "action"=>"update", "id"=>"38", "controller"=>"admin/details", "db"=>""},{'user' => User.find_by_id(@db1_admin_user_id)}

    #redirect?
    assert_response :redirect
    #assert_redirected_to :controller => "databases", :action => "list"

    #updated?
    detail = Detail.find 38
    assert_equal "Ville", detail.name
  end

  def test_show

    get :show, {:id => 52},
      {
        'user' => User.find_by_id(@db1_admin_user_id),
        'return-to' => @controller.url_for('admin/details/list')
      }
    #success?
    assert_response :success
    #no form
    #check doesn't work due to javascript code
    #assert_no_tag :tag => "form"
  end
=begin
  def test_index
    get :index
    assert_rendered_file 'list'
  end

  def test_list
    get :list
    assert_rendered_file 'list'
    assert_template_has 'details'
  end

  def test_show
    get :show, 'id' => 1
    assert_rendered_file 'show'
    assert_template_has 'details'
    assert_valid_record 'details'
  end


  def test_create
    num_details = Details.find_all.size

    post :create, 'details' => { }
    assert_redirected_to :action => 'list'

    assert_equal num_details + 1, Details.find_all.size
  end

  def test_edit
    get :edit, 'id' => 1
    assert_rendered_file 'edit'
    assert_template_has 'details'
    assert_valid_record 'details'
  end

  def test_update
    post :update, 'id' => 1
    assert_redirected_to :action => 'show', :id => 1
  end

  def test_destroy
    assert_not_nil Details.find(1)

    post :destroy, 'id' => 1
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      details = Details.find(1)
    }
  end
=end
end
