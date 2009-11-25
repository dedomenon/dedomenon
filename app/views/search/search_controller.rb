class SearchController < ApplicationController

  before_filter :login_required
  model :date_detail_value
  layout :determine_layout
  before_filter :check_all_ids

  def check_all_ids
    if params["database_id"]
	@db = Database.find params["database_id"]
    elsif params["entity_id"]
	@db = Entity.find(params["entity_id"]).database
    end
     if ! user_dbs.include? @db
       flash["error"] = "entity_not_in_your_dbs"
       redirect_to :controller => "database"
     end
  end

  def index
  end

  def simple_search_form
    @databases_list  = session["user"].account.databases.collect{|d| [d.name, d.id]}.unshift [t("madb_choose_database"),0]
    if params["entity_id"] and params["entity_id"].to_i>0
      @details = Entity.find(params["entity_id"]).details
      @details_list = @details.collect{|d| [d.name, d.detail_id]}.unshift [t("madb_all"),0]
    end
  end

  def search_results
####################################
#First way: get entities and filter
####################################
#    if params["entity_id"].to_i>0
#      unfiltered_list = Instance.find(:all, "entity_id='#{params["entity_id"]}'")
#      entity = Entity.find params["entity_id"]
#      entities = [ entity ]
#    else
#      unfiltered_list = Instance.find(:all)
#      entities = Entity.find(:all)
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
    if params["entity_id"] and params["entity_id"].to_i>0
      @entities = [ Entity.find params["entity_id"] ]
    else
      @entities = Database.find(params["database_id"]).entities
    end

  end

  def list_for_entity
    @list = {}
    instances_list = []
    corresponding_values(params["value"], params["entity_id"], params["detail_id"]).each do |v|
      instance = v.instance
      instances_list << instance if !instances_list.include? instance
    end
    if instances_list.length==0
      render_nothing
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
    crosstab_query, @not_in_list_view  = crosstab_query_for_entity(params["entity_id"])
    @list = CrosstabObject.find_by_sql("select * from #{crosstab_query} where id in (#{ids_list}) order by  #{order} limit #{limit} offset #{offset}")
  end

  def corresponding_values(value,entity_id=0, detail_id=0)
    @list = {}
    # detail_values
    condition = "value ilike '%#{value}%'"
    if entity_id.to_i>0
      if detail_id.to_i==0
        condition="#{condition} and detail_id in (select detail_id from entities2details where entity_id=#{entity_id}) and instance_id in (select id from instances where entity_id=#{entity_id})"
      else
        condition+=" and detail_id = #{detail_id} and instance_id in (select id from instances where entity_id=#{entity_id})"
      end
    end

    r = DetailValue.find(:all, condition)

    # ddl_detail_values
    condition = ""
    if entity_id.to_i>0
      if detail_id.to_i==0
        condition="detail_id in (select detail_id from entities2details where entity_id=#{entity_id}) and instance_id in (select id from instances where entity_id=#{entity_id})"
      else
        condition+=" and detail_id = #{detail_id} and instance_id in (select id from instances where entity_id=#{entity_id})"
      end
    end

    a=DdlDetailValue.find(:all, condition).reject{|v| (v.value=~Regexp.new(value))==nil }

    r.concat  a

    # date_detail_values
    condition = "value ilike '%#{value}%'"
    if entity_id.to_i>0
      if detail_id.to_i==0
        condition="#{condition} and detail_id in (select detail_id from entities2details where entity_id=#{entity_id}) and instance_id in (select id from instances where entity_id=#{entity_id})"
      else
        condition+=" and detail_id = #{detail_id} and instance_id in (select id from instances where entity_id=#{entity_id})"
      end
    end
    a=DateDetailValue.find(:all, condition)
    r.concat   a

    r

  end


  def results_page
    search_results
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
    if ["list_for_entity", "simple_search_form"].include? params["action"]
      return nil
    else
      return "application"
    end
  end
end
