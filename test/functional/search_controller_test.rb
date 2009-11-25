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
require 'search_controller'

# Re-raise errors caught by the controller.
class SearchController; def rescue_action(e) raise e end; end

class SearchControllerTest < ActionController::TestCase
  
  fixtures  :account_types, 
            :accounts, 
            :databases, 
            :data_types, 
            :detail_status, 
            :detail_value_propositions, 
            :details, 
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
            :user_types, 
            :users
  
  def setup
    @controller = SearchController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @db1_user_id = 2
  end
  
  # search all entities in db demo_forem for string "aud"
  # -----------------------------------------------------
  def test_search_all_entities_for_aud
     get :results_page, {'entity_id' => 0, 'value' => "aud", :database_id => 6}, { 'user' => User.find_by_id(@db1_user_id)}
     assert_response :success
     #Check we get 3 contacts returned
     assert_tag :tag => "div", :attributes => {:id => "contacts_search_result_div"} , :child => { :tag => "table", :children => { :only => { :tag => "tr"} , :count => 4}}
	 assert_no_tag :tag=> "select", :attributes => { :name => "detail_id"} 
     #Check we get  the contacts raphael, cahty and florence
     assert_tag :tag => "div", :attributes => {:id => "contacts_search_result_div"} , :child => { :tag=> "table" , :child => { :tag => "tr" , :child => { :tag => "td", :content => "Raphaël"} }, :child => { :tag => "tr" , :child => { :tag => "td", :content => "Carol"} }, :child => { :tag => "tr" , :child => { :tag => "td", :content => "Florence"} }}
     #Order links
     assert_tag :tag => "div", :attributes => {:id => "contacts_search_result_div"} , :child => { :tag=> "table" , :child => { :tag => "tr" , :child => { :tag => "th", 
	     :child => { :tag => "a", :content => "company_email", :attributes => { :onclick => Regexp.new("/search/list_for_entity\\?.*contacts_search_result_order=company_email")  }},
	     :child => { :tag => "a", :content => "fonction", :attributes => { :onclick => Regexp.new("/search/list_for_entity\\?.*contacts_search_result_order=fonction")  }},
	     :child => { :tag => "a", :content => "nom", :attributes => { :onclick => Regexp.new("/search/list_for_entity\\?.*contacts_search_result_order=nom")  }},
	     :child => { :tag => "a", :content => "prenom", :attributes => { :onclick => Regexp.new("/search/list_for_entity\\?.*contacts_search_result_order=prenom")  }},
	:child => { :tag => "a", :content => "service", :attributes => { :onclick => Regexp.new("/search/list_for_entity\\?.*contacts_search_result_order=service")  }}
     }  }}

	 #Check search form is filled correctly
	 assert_tag :tag => "select", :attributes => {:name => "database_id", :id => "database_id"}, :child => { :tag=> "option", :attributes => { :value => "6", :selected => "selected"}, :content => "demo_forem"} 
	 assert_tag :tag => "select", :attributes => {:name => "entity_id", :id => "entity_id"}, :child => { :tag=> "option", :attributes => { :value => "0", :selected => "selected"}, :content => "all"} 
	 assert_tag :tag=> "input", :attributes => { :type => "text", :name => "value", :value => "aud"} 
     
  end

  def test_search_with_star
     get :results_page, {'entity_id' => 0, 'value' => "*", :database_id => 6}, { 'user' => User.find_by_id(@db1_user_id)}
     assert_response :success
  end

  def test_search_all_entities_for_aud_in_inexisting_database
     get :results_page, {'entity_id' => 0, 'value' => "aud", :database_id => 123435}, { 'user' => User.find_by_id(@db1_user_id)}
     assert_response :redirect
     assert_redirected_to :controller => "search"
  end



  def test_search_all_entities_for_aud_in_inexisting_entity
     get :results_page, {'entity_id' => 12423, 'value' => "aud", :database_id => 6}, { 'user' => User.find_by_id(@db1_user_id)}
     assert_response :redirect
     assert_redirected_to :controller => "search"
  end

  def test_search_contact_entities_for_inexisting_detail_with_a
     get :results_page, {'entity_id' => 12, 'value' => "a", :database_id => 6, :detail_id=>1256 }, { 'user' => User.find_by_id(@db1_user_id)}
     assert_response :redirect
     assert_redirected_to :controller => "search"
  end

  def test_search_contact_entities_for_nexisting_detail_but_not_linked_with_a
     get :results_page, {'entity_id' => 12, 'value' => "a", :database_id => 6, :detail_id=>38 }, { 'user' => User.find_by_id(@db1_user_id)}
     assert_response :redirect
     assert_redirected_to :controller => "search"
  end

  # search contacts prenom in db demo_forem for string "a"
  # ------------------------------------------------------
  def test_search_contact_entities_for_prenom_with_a
     get :results_page, {'entity_id' => 12, 'value' => "a", :database_id => 6, :detail_id=>56 }, { 'user' => User.find_by_id(@db1_user_id)}
     assert_response :success
     #Check we get 3 contacts returned
     assert_tag :tag => "div", :attributes => {:id => "contacts_search_result_div"} , :child => { :tag => "table", :child => {:tag => "tbody", :children => { :only => { :tag => "tr"} , :count => 6}}}
     #Check we get  the contacts raphael, cahty and florence
     assert_tag  :tag=> "tbody" , 
		 :child => { :tag => "tr" , :child => { :tag => "td", :content => "Raphaël"} }, 
		 :child => { :tag => "tr" , :child => { :tag => "td", :content => "Carol"} }, 
		 :child => { :tag => "tr" , :child => { :tag => "td", :content => "Elisabeth"} },
		 :child => { :tag => "tr" , :child => { :tag => "td", :content => "Stéphanie"} },
		 :child => { :tag => "tr" , :child => { :tag => "td", :content => "Christiane"} }
	 
     #Order links
     assert_tag  :tag=> "thead" , :child => { :tag => "tr" , :child => { :tag => "th", 
	     :child => { :tag => "a", :content => "company_email", :attributes => { :onclick => Regexp.new("/search/list_for_entity\\?.*contacts_search_result_order=company_email")  }},
	     :child => { :tag => "a", :content => "fonction", :attributes => { :onclick => Regexp.new("/search/list_for_entity\\?.*contacts_search_result_order=fonction")  }},
	     :child => { :tag => "a", :content => "nom", :attributes => { :onclick => Regexp.new("/search/list_for_entity\\?.*contacts_search_result_order=nom")  }},
	     :child => { :tag => "a", :content => "prenom", :attributes => { :onclick => Regexp.new("/search/list_for_entity\\?.*contacts_search_result_order=prenom")  }},
	:child => { :tag => "a", :content => "service", :attributes => { :onclick => Regexp.new("/search/list_for_entity\\?.*contacts_search_result_order=service")  }}
     }  }

	 #Check search form is filled correctly
	 assert_tag :tag => "select", :attributes => {:name => "database_id", :id => "database_id"}, :child => { :tag=> "option", :attributes => { :value => "6", :selected => "selected"}, :content => "demo_forem"} 
	 assert_tag :tag => "select", :attributes => {:name => "entity_id", :id => "entity_id"}, :child => { :tag=> "option", :attributes => { :value => "12", :selected => "selected"}, :content => "contacts"} 
	 assert_tag :tag => "select", :attributes => {:name => "detail_id"}, :child => { :tag=> "option", :attributes => { :value => "56", :selected => "selected"}, :content => "prenom"} 
	 assert_tag :tag=> "input", :attributes => { :type => "text", :name => "value", :value => "a"} 
     
  end

  # search contacts prenom in db demo_forem for string "a"
  # ------------------------------------------------------
  def test_search_all_entities_with_a
     get :results_page, {'entity_id' => 0, 'value' => "rap", :database_id => 6, :detail_id=>0 }, { 'user' => User.find_by_id(@db1_user_id)}
     assert_response :success
     # we have a div with id content -> used application layout
		 assert_tag :tag => "div", :attributes => { :id => "content"}
		 #we have tags for the different entities found matching
		 assert_tag :tag => "div", :attributes => { :id => "societe_search_result_div"}
		 assert_tag :tag => "div", :attributes => { :id => "contacts_search_result_div"}
		 # we have found no visit
		 assert_no_tag :tag => "div", :attributes => { :id => "visite_search_result_div"}
  end



  # Formation search
  # ----------------

  def test_search_for_formation_form_ok
     get :index, {'database_id'=> 6, 'entity_id' => 15}, { 'user' => User.find_by_id(@db1_user_id)}
	 assert_tag :tag => "select", :attributes => {:name => "database_id", :id => "database_id"}, :child => { :tag=> "option", :attributes => { :value => "6", :selected => "selected"}, :content => "demo_forem"} 
	 assert_tag :tag => "select", :attributes => {:name => "entity_id", :id => "entity_id"}, :child => { :tag=> "option", :attributes => { :value => "15", :selected => "selected"}, :content => "formation"} 
	 assert_tag :tag=> "input", :attributes => { :type => "text", :name => "value", :value => ""} 
  end

  ##################
  # list_for_entity#
  ##################

  def test_simple_entity_list_3_contacts_returned
	get :list_for_entity ,{ 'entity_id' => 12, 'value' => "aud"}, { 'user' => User.find_by_id(@db1_user_id)} 
	  assert_response :success
     #Check we get 3 contacts returned
     assert_no_tag :tag => "div", :attributes => {:id => "contacts_search_result_div"} , :child => { :tag => "tbody", :children => { :only => { :tag => "tr"} , :count => 3}}
     assert_tag({ :tag => "tbody", :children => { :only => { :tag => "tr"} , :count => 3}})
	 # view and Edit links
	 assert_tag :tag=> "tr", 
		 :child => { :tag => "td", :content => "rb@raphinou.com"} ,
		 :child => { :tag => "td", :child => { :tag =>"a", :attributes => { :href=> Regexp.new("/entities/view/72") } }},
		 :child => { :tag => "td", :child => { :tag =>"a", :attributes => { :href=> Regexp.new("/entities/edit/72") } }}
	 assert_tag :tag=> "tr", 
		 :child => { :tag => "td", :content => "florence.audous@consultaix.com"} ,
		 :child => { :tag => "td", :child => { :tag =>"a", :attributes => { :href=> Regexp.new("/entities/view/81") } }},
		 :child => { :tag => "td", :child => { :tag =>"a", :attributes => { :href=> Regexp.new("/entities/edit/81") } }}
     #Order links
     assert_tag( { :tag=> "thead" , :child => { :tag => "tr" , :child => { :tag => "th", 
             :child => { :tag => "a", :content => "company_email", :attributes => { :onclick => Regexp.new("/search/list_for_entity\\?.*contacts_search_result_order=company_email")  }},
             :child => { :tag => "a", :content => "fonction", :attributes => { :onclick => Regexp.new("/search/list_for_entity\\?.*contacts_search_result_order=fonction")  }},
             :child => { :tag => "a", :content => "nom", :attributes => { :onclick => Regexp.new("/search/list_for_entity\\?.*contacts_search_result_order=nom")  }},
             :child => { :tag => "a", :content => "prenom", :attributes => { :onclick => Regexp.new("/search/list_for_entity\\?.*contacts_search_result_order=prenom")  }},
             :child => { :tag => "a", :content => "service", :attributes => { :onclick => Regexp.new("/search/list_for_entity\\?.*contacts_search_result_order=service")  }}
     }  }})

     #check order of fields in list
     assert_equal %w(nom prenom fonction service company_email), assigns["ordered_fields"]
  end

  def test_simple_entity_list_3_contacts_returned_as_csv
	get :list_for_entity ,{ 'entity_id' => 12, 'value' => "aud", :format => "csv" }, { 'user' => User.find_by_id(@db1_user_id)} 
	  assert_response :success
     #Check we get 3 contacts returned
    assert_equal 3, assigns["list"].length
    #check we return all columns
    assert_equal 7, assigns["list"][0].attributes.length
    expected_csv="\"nom\";\"prenom\";\"fonction\";\"service\";\"coordonees_specifiques\";\"company_email\";\n\"BAuduin\";\"Rapha\303\253l\";\"\";\"\";\"trucksharing, madb, easynet\";\"rb@raphinou.com\";\n\"Bauduin\";\"Carol\";\"Employ\303\251e\";\"\";\"\";\"carol.bauduin@o-nuclear.be\";\n\"Audux\";\"Florence\";\"Consultante\";\"\";\"\";\"florence.audux@consultaix.com\";\n"

    assert_equal @response.body, expected_csv

  end

  def test_simple_entity_list_0_societe_returned
	get :list_for_entity ,{ 'entity_id' => 11, 'value' => "ffsfsgfgd"}, { 'user' => User.find_by_id(@db1_user_id)} 
	assert_response :success
     #Check we get 0 entities returned
     assert_no_tag :tag => "div", :attributes => {:id => "contacts_search_result_div"} 
  end

  def test_simple_entity_wrong_user
	get :list_for_entity ,{ 'entity_id' => 11, 'value' => "ffsfsgfgd"}, { 'user' => User.find_by_id(@db2_user_id)} 
	assert_response :redirect
    assert_redirected_to({:controller => "authentication", :action => "login"})
  end

  # Check page navigation links and order links
  # -------------------------------------------
  def test_entity_list_all_contacts
	get :list_for_entity ,{ 'entity_id' => 12, 'detail_id' => 48}, { 'user' => User.find_by_id(@db1_user_id)} 
	assert_response :success
	# no link to page 1 as this is the one displayed
	assert_no_tag :tag => "span", :attributes => { :class => "navigation_link"}, :child => { :tag =>"a", :attributes => {:onclick => Regexp.new("contacts_search_result_page=1")}} 
	# link to page 2 as this is page 1 displayed
	assert_tag :tag => "span", :attributes => { :class => "navigation_link"}, :child => { :tag =>"a", :attributes => {:onclick => Regexp.new("contacts_search_result_page=2")}} 
	#number of rows displayed
	assert_tag :tag =>"tbody", :children => { :only => {:tag => "tr", :child => { :tag => "td"} }, :count => 10}
  end

  def test_entity_list_all_contacts_page_1
	get :list_for_entity ,{ 'entity_id' => 12, 'detail_id' => 48, :contacts_search_result_page=>1}, { 'user' => User.find_by_id(@db1_user_id)} 
	assert_response :success
	# no link to page 1 as this is the one displayed
	assert_no_tag :tag => "span", :attributes => { :class => "navigation_link"}, :child => { :tag =>"a", :attributes => {:onclick => Regexp.new("contacts_search_result_page=1")}} 
	assert_tag :tag => "span", :attributes => { :class => "navigation_link"}, :child => { :tag =>"a", :attributes => {:onclick => Regexp.new("contacts_search_result_page=2")}} 
	# ordering links (fonction)
	assert_tag :tag => "th", :child => { :tag =>"a", :content => "fonction", :attributes => {:onclick => Regexp.new("contacts_search_result_page=1")}} 
	assert_tag :tag => "th", :child => { :tag =>"a", :content => "fonction", :attributes => {:onclick => Regexp.new("contacts_search_result_order=fonction")}} 
	#number of rows displayed
	assert_tag :tag =>"tbody", :children => { :only => {:tag => "tr", :child => { :tag => "td"} }, :count => 10}
  end

  def test_entity_list_all_contacts_page_2
	get :list_for_entity ,{ 'entity_id' => 12, 'detail_id' => 48, :contacts_search_result_page=>2}, { 'user' => User.find_by_id(@db1_user_id)} 
	assert_response :success
	# no link to page 2 as this is the one displayed
	assert_no_tag :tag => "span", :attributes => { :class => "navigation_link"}, :child => { :tag =>"a", :attributes => {:onclick => Regexp.new("contacts_search_result_page=2")}} 
	# link to page 1 as this is page 2 displayed
	assert_tag :tag => "span", :attributes => { :class => "navigation_link"}, :child => { :tag =>"a", :attributes => {:onclick => Regexp.new("contacts_search_result_page=1")}} 
	#number of rows displayed
	assert_tag :tag =>"tbody", :children => { :only => {:tag => "tr", :child => { :tag => "td"} }, :count => 5}
  end

  def test_entity_list_all_contacts_page_2_ordered_by_function
	get :list_for_entity ,
    { 
      :entity_id => 12, 
      :detail_id => 48, 
      :contacts_search_result_page => 2, 
      :contacts_search_result_order => "fonction"
    }, 
    { 'user' => User.find_by_id(@db1_user_id)} 
  
	assert_response :success
	# no link to page 2 as this is the one displayed
	assert_no_tag :tag => "span", :attributes => { :class => "navigation_link"}, :child => { :tag =>"a", :attributes => {:onclick => Regexp.new("contacts_search_result_page=2")}} 
	# link to page 1 as this is page 2 displayed
	assert_tag :tag => "span", :attributes => { :class => "navigation_link"}, :child => { :tag =>"a", :attributes => {:onclick => Regexp.new("contacts_search_result_order=fonction")}} 
	# ordering links by prenom keeps page and doesn't keep current search order
	assert_tag :tag => "th", :child => { :tag =>"a", :content => "prenom", :attributes => {:onclick => Regexp.new("contacts_search_result_page=2")}} 
	assert_tag :tag => "th", :child => { :tag =>"a", :content => "prenom", :attributes => {:onclick => Regexp.new("contacts_search_result_order=prenom")}} 
	# no header with current sort order
	assert_no_tag :tag => "th", :child => { :tag =>"a", :content => "fonction", :attributes => {:onclick => Regexp.new("contacts_search_result_order=info")}} 
	#number of rows displayed
	assert_tag :tag =>"tbody", :children => { :only => {:tag => "tr", :child => { :tag => "td"} }, :count => 5}

	#first row displayed
  # FIXME: Elisabeth NOT APEARING!
  # REASON: Because the Elisabeth is not the value for the detail 48 
  # in test fixtures instead its for detail 56!
	#assert_tag :tag =>"td", :content => "Elisabeth"
	assert_tag :tag =>"td", :content => "Dimitri"
	assert_tag :tag =>"td", :content => "Rapha\303\253l"
	assert_tag :tag =>"td", :content => "H\303\251l\303\250ne"
	assert_tag :tag =>"td", :content => "Christiane"
	assert_no_tag :tag =>"td", :content => "BAuduin"
	assert_no_tag :tag =>"td", :content => "Peter"
	assert_no_tag :tag =>"td", :content => "Joelle"
	assert_no_tag :tag =>"td", :content => "Robert"
	assert_no_tag :tag =>"td", :content => "Vincent"
	assert_no_tag :tag =>"td", :content => "Florence"
	assert_no_tag :tag =>"td", :content => "Nicole"
	assert_no_tag :tag =>"td", :content => "St\303\251phanie"
  #FIXME: Ermioni APPEARING!
	#assert_no_tag :tag =>"td", :content => "Ermioni"
	assert_no_tag :tag =>"td", :content => "C/athy"

	# check refresh link
	assert_tag :tag=> "a", :content => "madb_refresh", :attributes => { :onclick => Regexp.new("contacts_search_result_page=2")}
	assert_tag :tag=> "a", :content => "madb_refresh", :attributes => { :onclick => Regexp.new("contacts_search_result_order=fonction")}
	assert_tag :tag=> "a", :content => "madb_refresh", :attributes => { :onclick => Regexp.new("detail_id=48")}
	assert_tag :tag=> "a", :content => "madb_refresh", :attributes => { :onclick => Regexp.new("entity_id=12")}
	 
	# check open in new window link
		assert_tag :tag => "a", :child => { :tag => "img", :attributes => { :alt => "madb_open_in_new_window"}}, :attributes => { :target => "contacts_search_result_window", :href => Regexp.new("contacts_search_result_page=2"), :title => "madb_open_in_new_window"}
		assert_tag :tag => "a", :child => { :tag => "img", :attributes => { :alt => "madb_open_in_new_window"}}, :attributes => { :target => "contacts_search_result_window", :href => Regexp.new("contacts_search_result_order=fonction"), :title => "madb_open_in_new_window"}
		assert_tag :tag => "a", :child => { :tag => "img", :attributes => { :alt => "madb_open_in_new_window"}}, :attributes => { :target => "contacts_search_result_window", :href => Regexp.new("detail_id=48"), :title => "madb_open_in_new_window"}
		assert_tag :tag => "a", :child => { :tag => "img", :attributes => { :alt => "madb_open_in_new_window"}}, :attributes => { :target => "contacts_search_result_window", :href => Regexp.new("entity_id=12"), :title => "madb_open_in_new_window"}
		assert_tag :tag => "a", :child => { :tag => "img", :attributes => { :alt => "madb_open_in_new_window"}}, :attributes => { :target => "contacts_search_result_window", :href => Regexp.new("popup=t"), :title => "madb_open_in_new_window"}
  end


  #----------------------
  #order by integer field
  #----------------------
  def test_entity_list_all_societe_page_2_ordered_by_employees
	get :list_for_entity ,{ 'entity_id' => 11, 'detail_id' => 0, :societe_search_result_page=>1, :societe_search_result_order => "personnes_occuppees"}, { 'user' => User.find_by_id(@db1_user_id)} 
	assert_response :success
	# no link to page 1 as this is the one displayed
	assert_no_tag :tag => "span", :attributes => { :class => "navigation_link"}, :child => { :tag =>"a", :attributes => {:onclick => Regexp.new("societe_search_result_page=1")}} 

	#first rows displayed
	assert_tag :tag =>"td", :content => "raphinou"
	assert_tag :tag =>"td", :content => "Axios"
	assert_tag :tag =>"td", :content => "Banque Degroof"
	assert_tag :tag =>"td", :content => "valtech"
	assert_tag :tag =>"td", :content => "BARDAF"
	assert_tag :tag =>"td", :content => "O-nuclear"
	assert_tag :tag =>"td", :content => "Experteam"
	assert_tag :tag =>"td", :content => "Commission  europ\303\251enne"
	assert_tag :tag =>"td", :content => "Easynet Belgium"
	assert_tag :tag =>"td", :content => "Mind"
	assert_no_tag :tag =>"td", :content => "O'Conolly & Associates"

  list = assigns["list"]
  assert_equal 71, list[0].id
  assert_equal 69, list[1].id
  assert_equal 77, list[2].id
  assert_equal 89, list[3].id
  assert_equal 88, list[4].id
  assert_equal 79, list[5].id
  assert_equal 78, list[6].id
  assert_equal 73, list[7].id
  assert_equal 80, list[8].id
  assert_equal 91, list[9].id

  end















  # check popup window, all contacts, page 2
  def test_popup_window
	get :list_for_entity ,{ 'entity_id' => 12, 'detail_id' => 48, :contacts_search_result_page=>2, :contacts_search_result_order => "fonction", :popup => 't'}, { 'user' => User.find_by_id(@db1_user_id)} 
	assert_response :success
	# we have a popup_content rather than a content div
	assert_tag :tag => "div", :attributes => { :id => "popup_content"}
	# we don't display the menu
	assert_no_tag :tag => "div", :attributes => { :class=> "menu"} 
	# we display a warning to the user
	assert_tag :tag => "span", :attributes => { "class" => /popup_warning/ }
	# we have the view links keeping the popup=t
	assert_tag :tag => "a", :attributes => { "href" => Regexp.new("popup=t") }, :child => { :tag => "img", :attributes => { :src => /view/}}
	# we have the edit links keeping the popup=t
	assert_tag :tag => "a", :attributes => { "href" => Regexp.new("popup=t") }, :child => { :tag => "img", :attributes => { :src => /edit/}}
	# we have the order links keeping the popup=t
	assert_tag :tag => "a", :attributes => { "onclick" => Regexp.new("popup=t") }, :content => "company_email"
	assert_tag :tag => "a", :attributes => { "onclick" => Regexp.new("popup=t") }, :content => "fonction"
	assert_tag :tag => "a", :attributes => { "onclick" => Regexp.new("popup=t") }, :content => "nom"
	#we have the div used in remote_links
	assert_tag :tag=> "div", :attributes => { :id => "contacts_search_result_div"  }
	assert_tag :tag=> "a", :content => "1", :attributes => { :onclick => /contacts_search_result_div/  }
	assert_no_tag :tag=> "span", :content => "2", :attributes => { :class => "navigation_links" }
	assert_tag :tag=> "a", :content => "company_email", :attributes => { :onclick => /contacts_search_result_div/  }
	assert_tag :tag=> "a", :content => "fonction", :attributes => { :onclick => /contacts_search_result_div/  }
	assert_tag :tag=> "a", :content => "madb_refresh", :attributes => { :onclick => /contacts_search_result_div/  }
  end

  # search all entities in db demo_forem for string "aud"
  # -----------------------------------------------------
  def test_search_all_entities_for_aud
     get :results_page, {'entity_id' => 0, 'value' => "", :database_id => 6}, { 'user' => User.find_by_id(@db1_user_id)}
     assert_response :success
     assert_no_tag :tag => "div", :attributes => { :id => "contacts_search_result_div"} 
     assert_no_tag :tag => "div", :attributes => { :id => "societe_search_result_div"} 
     assert_no_tag :tag => "div", :attributes => { :id => "visite_search_result_div"} 

  end


  def test_simple_search_form_database_id_0
    xhr :get, :simple_search_form, { :database_id => "0"}, { 'user' => User.find_by_id(@db1_user_id)}
    assert_response :success
    assert_tag :tag => "select", :attributes => { :id => "database_id"}
    assert_no_tag :tag => "select", :attributes => { :id => "entity_id"}
    assert_no_tag :tag => "select", :attributes => { :id => "detail_id"}
    assert_no_tag :tag => "input", :attributes => { :id => "search_value"}
  end

  def test_simple_search_form_database_id_6
    xhr :get, :simple_search_form, { :database_id => "6"}, { 'user' => User.find_by_id(@db1_user_id)}
    assert_response :success
    assert_tag :tag => "select", :attributes => { :id => "database_id"}, :child => { :tag => "option", :attributes => { :selected => "selected", :value => "6"} }
    assert_tag :tag => "select", :attributes => { :name => "entity_id"}
    assert_tag :tag => "select", :attributes => { :name => "entity_id"}, :child => { :tag => "option", :attributes => { :selected => "selected", :value => "0"} }
    assert_no_tag :tag => "select", :attributes => { :name => "detail_id"}
    assert_tag :tag => "input", :attributes => { :id => "search_value"}
  end

  def test_simple_search_form_database_id_6_entity_id_12
    xhr :get, :simple_search_form, { :database_id => "6", :entity_id => "12" }, { 'user' => User.find_by_id(@db1_user_id)}
    assert_response :success
    assert_tag :tag => "select", :attributes => { :id => "database_id"}, :child => { :tag => "option", :attributes => { :selected => "selected", :value => "6"} }
    assert_tag :tag => "select", :attributes => { :name => "entity_id"}, :child => { :tag => "option", :attributes => { :selected => "selected", :value => "12"} }
    assert_tag :tag => "select", :attributes => { :name => "detail_id"}
    assert_tag :tag => "input", :attributes => { :id => "search_value"}
  end
end
