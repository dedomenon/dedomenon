# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 



def register_datatype(options={})
  return if !ActiveRecord::Base.connection.tables.include? 'data_types'
  
  raise 'DataType name not provided' if !options[:name]
  raise 'DataType handling class not provided' if !options[:class_name]
        
  if DataType.exists?(["name=? AND class_name=?", options[:name], options[:class_name]])
    return
  else
    DataType.create!(:name => options[:name], :class_name => options[:class_name])
  end
end

def unregister_datatype(options={})
  return if !ActiveRecord::Base.connection.tables.include? 'data_types'
  
  raise 'DataType name not provided' if !options[:name]
  raise 'DataType handling class not provided' if !options[:class_name]
        
  if !DataType.exists?(["name=? AND class_name=?", options[:name], options[:class_name]])
    return
  else
    DataType.delete_all(["name=? AND class_name=?", options[:name], options[:class_name]])
  end
end
      
 
      
  
