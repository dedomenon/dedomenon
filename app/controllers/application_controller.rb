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

# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.
# 
  require_dependency "login_system"
  require_dependency "translations"
class ApplicationController < ActionController::Base
    include LoginSystem
    extend LoginSystem::AuthSchemes
    helper_method :current_user
    include Translations
  
  before_filter :set_user_lang
    
    #model :user
    #model :translation


  # This url is the base url of the application
  # Note that it is an adhoc solution for now.
  # We will make the application to generate this
  # automatically later on.
  @@base_url = 'http://localhost:3000/'
  
  
  helper_method :t
  after_filter :set_encoding, :except => ["apply_edit", "apply_link_to_new"]
    
  # *Description*
  #   Sets the encoding for the responce to be UTF-8
  def set_encoding
    unless params["format"]=="csv"
      response.headers["Content-Type"] = "text/html; charset=UTF-8"
    end
  end


  #from a module included in config/environment.rb
  helper_method :class_from_name

  # *Description*
  #   Returns the databases of the user.
  def user_dbs
    session["user"].account.databases
  end

  # *Description*
  #   Returns the databases of the user.
  def user_admin_dbs
    session["user"].account.databases
  end


# PENDING: Document and understand this method
  def crosstab_query_for_entity(entity_id, h = {})
    defaults = { :display => "detail" }
    not_in_list_fields = []
    details_kept = []

    options = defaults.update h
    entity = Entity.find entity_id
    details_select = ""
    as_string = "id int "
    
    ordinal = 1
    entity.details.sort{ |a,b| a.name.downcase <=>b.name.downcase }.each do |detail|
      #entity_detail = EntityDetail.find :first, :condition => ["entity_id = ? and detail_id =?",entity.id, detail.id]
      if detail.displayed_in_list_view=='f'
        not_in_list_fields.push detail.name.downcase
        next if options[:display]=="list"
      end
      details_kept.push detail
      #'select name from (select 1 as id , ''contract_description'' as name UNION select 2 as id , ''contract_price'' as name  UNION select 3 as id ,''contractors_name'' as name UNION select 4 as id ,''telephone'' as name) as temporary_table'
      details_select += " UNION select #{ordinal} as id, ''#{detail.name.downcase}'' as name"
      ordinal = ordinal + 1
      case detail.data_type.name
      #  when "short_text"
      #  when "long_text"
      #  when "date"
         when "madb_integer"
          as_string += ",  \"#{detail.name.downcase}\" bigint "
      #  when "choose_in_list"
         else
          as_string += ",  \"#{detail.name.downcase}\" text "
      end
    end

    if details_select.length==0
      return nil
    else
      details_select = "select name from (#{details_select}) as temporary_table"
      h = { :values_query =>"select distinct on (i.id, d.name) i.id, lower(d.name) as name, dv.value from instances i join detail_values dv on (dv.instance_id=i.id) join details d on (d.id=dv.detail_id) where i.entity_id=#{entity_id}
      union select distinct on (i.id, d.name) i.id, lower(d.name) as name, dv.value::text from instances i join date_detail_values dv on (dv.instance_id=i.id) join details d on (d.id=dv.detail_id)  where i.entity_id=#{entity_id}
      union select distinct on (i.id, d.name) i.id, lower(d.name) as name, dv.value::text from instances i join integer_detail_values dv on (dv.instance_id=i.id) join details d on (d.id=dv.detail_id) where i.entity_id=#{entity_id}
      union select distinct on (i.id, d.name) i.id, lower(d.name) as name, pv.value from instances i join ddl_detail_values dv join detail_value_propositions pv on (pv.id=dv.detail_value_proposition_id)  on (dv.instance_id=i.id) join details d on (d.id=dv.detail_id)  where i.entity_id=#{entity_id} order by id, name",
      :details_query => details_select.sub!(/UNION/,""),
      :as_string => "#{as_string}" }
      #[ "crosstab('#{h[:values_query]}', '#{h[:details_query]}') as (#{h[:as_string]})", not_in_list_fields ]
      return { 
        :query => "crosstab('#{h[:values_query]}', '#{h[:details_query]}') as (#{h[:as_string]})", 
        :not_in_list_view => not_in_list_fields, 
        :ordered_fields => details_kept.sort{|a,b| a.display_order<=>b.display_order}.collect{|d| d.name.downcase }}
    end
  end

  # returns one row with each column being a detail of the object. The name of the column is the id of the detail
  def details_query_for_instance( instance_id, h={})
    dt = [ "detail_values", "integer_detail_values", "date_detail_values"]
    cols = "d.id , v.value::text , e2d.display_order"
    query = dt.inject("") do  |q, t|
      q += "select d.id , v.value::text , e2d.display_order  from #{t} v join details d on (v.detail_id = d.id) join instances i on (i.id=v.instance_id) join entities e on (e.id=i.entity_id) join entities2details e2d on (e2d.detail_id=d.id and e2d.entity_id = e.id)   where instance_id = #{instance_id} union "
    end

    query += "select d.id , p.value::text, e2d.display_order  from ddl_detail_values v join details d on (v.detail_id = d.id) join detail_value_propositions p on (p.id=v.detail_value_proposition_id) join instances  i on (i.id=v.instance_id) join entities e on (e.id=i.entity_id) join entities2details e2d on (e2d.detail_id=d.id and e2d.entity_id = e.id)  where instance_id =#{instance_id}";

  end
  helper_method :crosstab_query_for_entity


  

 helper_method :details_query_for_instance
  # *Description*
  #  Returns true if the action is part of the request instead of the URL
  def embedded?
    ( params["action"]!=request.path_parameters["action"])
  end
  helper_method :embedded?

  # *Description*
  #   Sets the return path of the session
  def set_return_url
    session['return-to'] = request.request_uri
  end

  # *Description*
  #   Returns the account id
  #
  def get_account_id
    return session["user"].account_id
  end

  # Returns the Database ID
  def get_database_id
    return @db.id if @db
    return nil
  end

  #was necessary to have request not considered local.
  def local_request?
      false
  end

  def rescue_action_in_public(exception)
    case exception.class.to_s
    #, ActionController::UnknownAction
    when "ActiveRecord::RecordNotFound","ActionController::RoutingError"
      render(:file => "#{RAILS_ROOT}/public/404.html",
             :status => "404 Not Found")
    else
      render(:file => "#{RAILS_ROOT}/public/500.html",
             :status => "500 Error")
      SystemNotifier.deliver_exception_notification(self, request, exception)
    end
  end

  def admin_user_required
     if  !session["user"].admin_user?
       redirect_to :controller => "authentication", :action => "login" and return false
     end
     return true
  end
  
  

end

