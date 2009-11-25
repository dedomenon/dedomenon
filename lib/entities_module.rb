module EntitiesHelpers
  private

  # div id containing list displayed
  def list_id
    @list_id || "#{@entity.name}_list"
  end

  #defined which parameter to use for ordering the list
  def order_param
    "#{@list_id}_order"
  end

  # build order by clause for entities_list from parameters
  def order_by
    session["list_order"]||={}
    if params[order_param] and ! params["highlight"] or params["highlight"]==""
      order=CrosstabObject.connection.quote_string(params[order_param].to_s)
      session["list_order"][list_id]=order
    elsif session["list_order"].has_key? [list_id]
      order = session["list_order"][list_id]
    else
      order = "id"
    end
    return order
  end

  def is_id?(s)
    s.to_i.to_s == s
  end

  def detail_filter
    return nil if params["detail_filter"].nil?
    if is_id?(params["detail_filter"])
      return params["detail_filter"]
    else
      @details[params["detail_filter"]].id
    end 
  end

  def build_details_hash
    # Pick the details of this entity and populate them in a hash which is keyed by the name of the detail.
    details = {}
    EntityDetail.find(:all,:conditions =>  ["entity_id=?", @entity.id], :include => :detail).each do |d|
      details[d.detail.name.downcase]=d.detail
    end
    details
  end

  # method telling if the filter value we got must match the start of the values in the database
  # overwritten in rest::simple
  def match_start?
    false
  end
  # method telling if the filter value we got must match the end of the values in the database
  # overwritten in rest::simple
  def match_end?
    false
  end

  def leading_wildcard
    return '%' unless match_start?
    ''
  end
  def trailing_wildcard
    return '%' unless match_end?
    ''
  end
  # build where clause to crosstab query for entities_list, list_available_for_link
  def crosstab_filter
    if detail_filter.nil?
      return ""
    else
      detail = Detail.find detail_filter
      return "\"#{CrosstabObject.connection.quote_string(detail.name.downcase)}\" ilike '#{leading_wildcard}#{CrosstabObject.connection.quote_string(params["value_filter"].to_s)}#{trailing_wildcard}'"
    end
  end
    
  # returns display type to entities_list
  def list_display
    if detail_filter or  params["format"]=="csv"
      return "complete"
    else
      return "list"
    end
  end

  # returns page_number to display according to highlight value or the requested page
  def page_number(crosstab_query=nil)
    if params["highlight"] and params["highlight"]!=""
      @instance = Instance.find params["highlight"]
      #ERROR uploading empty file due to params["highlight"]
      query_filter = join_filters( [ crosstab_filter, "id=#{CrosstabObject.connection.quote_string(params["highlight"].to_s)}"])
      value_query = "select #{order_by} from #{crosstab_query} #{query_filter}"
      highlight_value_row =  CrosstabObject.connection.execute(value_query)[0]
      highlight_value = highlight_value_row[0] ? highlight_value_row[0] : highlight_value_row['id']
      query_filter = join_filters( [crosstab_filter, "#{order_by}<'#{CrosstabObject.connection.quote_string(highlight_value.to_s)}'" ])
      count_query = "select count(*) from #{crosstab_query} #{query_filter}"
      highlight_row = CrosstabObject.connection.execute(count_query)[0]
      highlight_count = highlight_row[0] ? highlight_row[0] : highlight_row['count']
      return  (highlight_count.to_i/list_length)+1
    else
      return params[list_id+"_page"]
    end
  end

  # facility to get number of items per page
  def list_length
    MadbSettings.list_length
  end

  def join_filters(filters)
    filters = filters.reject{|f| f.nil? or f.length==0}
    query_filter = ""
    query_filter = " where " + filters.join(" and ")  if filters.length > 0
    return query_filter
  end

  # returns one page of the list built buy crosstab_query (for entities_list)
  def get_paginated_list(crosstab_query, h = {})
    
    query_filter = join_filters(h [:filters])

    crosstab_count_row =  CrosstabObject.connection.execute("select count(*) from #{crosstab_query} #{query_filter}")[0]
    crosstab_count = crosstab_count_row[0] ? crosstab_count_row[0] : crosstab_count_row['count']
    #determine page to display.If we have a highlight parameter, always display the page of the highlighted item
    if crosstab_count.to_i>0
      @paginator = ApplicationController::Paginator.new self, crosstab_count.to_i, list_length, page_number(crosstab_query)
      limit, offset = @paginator.current.to_sql
      query = "select * from #{crosstab_query}  #{query_filter} order by \"#{order_by}\""
      if params["format"]!="csv"
        query += " limit #{limit} offset #{offset}"
      end
      return CrosstabObject.find_by_sql(query)
    else
      return []
    end
  end
end
