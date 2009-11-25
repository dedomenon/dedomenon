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

ActionController::Routing::Routes.draw do |map|


  # Route for detail_value validity checking. It should not be routed to the REST controllers
  map.connect '/app/entities/check_detail_value_validity', :controller => 'entities', :action => "check_detail_value_validity"


  
  # Add your own custom routes here.
  # The priority is based upon order of creation: first created -> highest priority.
  
  # This loads the routes from the rest-plugin. This line is needed if you've 
  # installed the REST API plugiln. This feature is provided by the engines plugin
  map.from_plugin 'rest_plugin' if File.exists? "#{RAILS_ROOT}/vendor/plugins/rest_plugin"
  
  # Here's a sample route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  map.connect '/app', :controller => "authentication", :action => "login"


  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  # Install the default route as the lowest priority.
  map.connect '/app/:controller/:action/:id'
  map.connect ':controller/:action/:id'
  # following is added to support the formats of response.
  map.connect ':controller/:action/:id.:format'
  map.connect '/app/:controller/:action/:id.:format'
  
  
end
