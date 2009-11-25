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

class SearchController < ApplicationController

  before_filter :login_required
#  model :date_detail_value
  layout :determine_layout
  before_filter :check_all_ids
  before_filter :set_return_url , :only => ["results_page"]

  # *Description*
  #   This method checks the request parameters for validity.
  #
  def check_all_ids
    if params["database_id"]
      return if params["database_id"]=="0"
      begin
      @db = Database.find params["database_id"]
      rescue ActiveRecord::RecordNotFound
        flash["error"]=t("madb_error_data_incorrect")
        redirect_to :controller => "search" and return false
      end
    end
    if params["entity_id"] and params["entity_id"].to_i!=0
      begin
      db = Entity.find(params["entity_id"]).database
      if params["database_id"] and db.id.to_i!=params["database_id"].to_i
        flash["error"]=t("madb_error_data_incorrect")
        redirect_to :controller=> "search" and return false
      end
      @db||= db
      rescue ActiveRecord::RecordNotFound
        flash["error"]=t("madb_error_data_incorrect")
        redirect_to :controller => "search" and return false
      end
    end
    if params["detail_id"] and params["detail_id"].to_i!=0
      begin
      db = Detail.find(params["detail_id"]).database
      if params["database_id"] and db.id.to_i!=params["database_id"].to_i
        flash["error"]=t("madb_error_data_incorrect")
        redirect_to :controller=> "search" and return false
      end
      @db||= db
      rescue ActiveRecord::RecordNotFound
        flash["error"]=t("madb_error_data_incorrect")
        redirect_to :controller => "search" and return false
      end
    end
     if ! user_dbs.include? @db
       flash["error"] = "entity_not_in_your_dbs"
       redirect_to :controller => "database" and return false
     end
  end

  # *Description*
  #   Shows the index page.
  #
  def index
    @title= t("madb_search")
  end

  # *Description*
  #   Shows the user simple search form
  #   
  # *Workflow*
  #   First all the databases from the account of the user of current session
  #   are collected. If the entity_id parameter is provided, then that entity
  #   is picked to collect all of its columns.
  #
  def simple_search_form
    @databases_list  = session["user"].account.databases.collect{|d| [d.name, d.id]}.unshift [t("madb_choose_database"),0]
    if params["entity_id"] and params["entity_id"].to_i>0
      @details = Entity.find(params["entity_id"]).details
      @details_list = @details.collect{|d| [t(d.name,{ :scope => "account"}), d.detail_id]}.unshift [t("madb_all"),0]
    end
  end

  def search_results
####################################
#First way: get entities and filter
####################################
#    if params["entity_id"].to_i>0
#      unfiltered_list = Instance.find(:all, :condition => "entity_id='#{params["entity_id"]}'")
#      entity = Entity.find params["entity_id"]
#      entities = [ entity ]
#    else
#      unfiltered_list = Instance.find :all
#      entities = Entity.find :all
#    end
#
#    if params["detail_id"].to_i>0
#      detail = Detail.find(params["detail_id"]).name
#    else
#      detail = nil
#    end
#    value = params["value"]
#
#    @list = {}
#    entities.each do |e|
#      @list[e.name]= []
#    end
#    unfiltered_list.each do |i|
#      @list[i.entity.name].push i if i.has_detail_value?(value, detail)
#    end
#######################################################
# Second way: find the details and get to the entities
#######################################################

#    @list = {}
#    corresponding_values(params["value"], params["entity_id"], params["detail_id"]).each do |v|
#      instance = v.instance
#      @list[instance.entity.name] ||= []
#      @list[instance.entity.name] << instance if !@list[instance.entity.name].include? instance
#    end
#    if @list.length<1
#      render_text t("no_result_found")
#    end
    @title = t("madb_search_results")
    if params["entity_id"] and params["entity_id"].to_i>0
      @entities = [ Entity.find(params["entity_id"])]
    else
      @entities = Database.find(params["database_id"]).entities
    end

  end

  def list_for_entity
    @entity = Entity.find params["entity_id"]
    @details = {}
    # Create a hash keyed by the name of the details.
    EntityDetail.find(:all,:conditions =>  ["entity_id=?", @entity.id], :include => :detail).each do |d|
      @details[d.detail.name.downcase]=d.detail
    end
    @list = {}
    instances_list = []
    corresponding_values(params["value"], params["entity_id"], params["detail_id"]).each do |v|
      instance = v.instance
      instances_list << instance if !instances_list.include? instance
    end
    if instances_list.length==0
      render :nothing => true
      return
    end

    entity = Entity.find params["entity_id"]
    @e = entity.name
    @list_id = "#{@e}_search_result"
    @div_class = "search_result"

    ids_list = instances_list.collect{|i| i.id}.join(",")
    if params["#{@list_id}_order"]
      order=params["#{@list_id}_order"]
    else
      order = "id"
    end

    @paginator = Paginator.new self, instances_list.length  , 10, params[@list_id+"_page"]
    limit, offset = @paginator.current.to_sql

    if params["format"]=="csv"
      list_display="complete"
    else
      list_display="list"
    end

    crosstab_result  = crosstab_query_for_entity(params["entity_id"], :display => list_display)
    crosstab_query     = crosstab_result[:query]
    @not_in_list_view  = crosstab_result[:not_in_list_view]
    @ordered_fields   = crosstab_result[:ordered_fields]

    query = "select * from #{crosstab_query} where id in (#{ids_list}) order by  \"#{order}\""
    if params["format"]!="csv"
      query+=" limit #{limit} offset #{offset}"
    end
    @list = CrosstabObject.find_by_sql(query)
    if params["format"]=="csv"
      csv_string = render_to_string :template => "entities/entities_list_csv"
      send_data(csv_string,:filename => @e+".csv", :type => 'text/csv; charset=UTF-8')
    end
  end

  def corresponding_values(value,entity_id=0, detail_id=0)
    @list = {}
    # detail_values
    condition = "value ilike ?"
    query_params = ["%#{value}%"]
    if entity_id.to_i>0
      if detail_id.to_i==0
        condition="#{condition} and detail_id in (select detail_id from entities2details where entity_id=?) and instance_id in (select id from instances where entity_id=?)"
        query_params.push(entity_id).push(entity_id)
      else
        condition+=" and detail_id = ? and instance_id in (select id from instances where entity_id=?)"
        query_params.push(detail_id).push(entity_id)
      end
    end

    r = DetailValue.find(:all,:conditions => [condition].concat(query_params) )

    # ddl_detail_values
    condition = ""
    query_params=[]
    if entity_id.to_i>0
      if detail_id.to_i==0
        condition="detail_id in (select detail_id from entities2details where entity_id=?) and instance_id in (select id from instances where entity_id=?)"
        query_params.push(entity_id).push(entity_id)
      else
        condition+=" detail_id = ? and instance_id in (select id from instances where entity_id=?)"
        query_params.push(detail_id).push(entity_id)
      end
    end

    a= DdlDetailValue.find(:all,:conditions => [condition].concat(query_params)).delete_if{|v| (v.value=~Regexp.new(Regexp.escape(value.to_s)))==nil}
    r.concat  a

    # date_detail_values
    condition = "value::text ilike ?"
    query_params=["%#{value}%"]
    if entity_id.to_i>0
      if detail_id.to_i==0
        condition="#{condition} and detail_id in (select detail_id from entities2details where entity_id=?) and instance_id in (select id from instances where entity_id=?)"
        query_params.push(entity_id).push(entity_id)
      else
        condition+=" and detail_id = ? and instance_id in (select id from instances where entity_id=?)"
        query_params.push(detail_id).push(entity_id)
      end
    end
    a=DateDetailValue.find(:all, :conditions => [condition].concat(query_params))
    r.concat   a

    r

  end


  def results_page
		if params["value"].nil? or params["value"]==""
			@error = t("madb_enter_value_to_search_for")
		else
			search_results
		end
  end


  def details_ddl
    begin
      @details = Entity.find(params["entity_id"]).details
      @ddl_id = "detail_id"
    rescue  ActiveRecord::RecordNotFound => e
      render_nothing
    end

  end

  def view
    redirect_to  :overwrite_params => {:controller => "entities", :action => "view"}
  end
  
  def edit
    redirect_to  :overwrite_params => {:controller => "entities", :action => "edit"}
  end

#doesn't work with current ajax helpers
#  def value_field
#    begin
#      @list = Detail.find(params["detail_id"]).detail_value_propositions
#      @ddl_id = "value_field"
#      render "details_ddl"
#
#    rescue  ActiveRecord::RecordNotFound => e
#      render_nothing
#    end
#
#  end

  def determine_layout
    if ( !params["popup"] and  ["list_for_entity", "simple_search_form"].include? params["action"]) or embedded? or request.xhr?
      return nil
    elsif  params["popup"]=="t"
      return "popup"
    else
      return "application"
    end
  end
end
