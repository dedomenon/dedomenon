module EntitiesHelpers
  private

  # div id containing list displayed
  def list_id
    @list_id || "#{@entity.name.underscorize}_list"
  end

  #defined which parameter to use for ordering the list
  def order_param
    "#{@list_id}_order"
  end

  # build order by clause for entities_list from parameters

  def is_id?(s)
    s.to_i.to_s == s
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
  # returns display type to entities_list
  def list_display
    if detail_filter or  params["format"]=="csv"
      return "complete"
    else
      return "list"
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
end
