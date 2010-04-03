module FormHelpers

  def form_field_id(i,o)
    entity = %Q{#{o[:form_id]}_#{o[:entity].name}}.gsub(/ /,"_")
    entity += "_"+o[:detail].field_name+i.to_s
  end

end
