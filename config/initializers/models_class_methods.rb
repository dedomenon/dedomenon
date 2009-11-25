module ModelsClassMethods
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    # determine if the class is available
    def class_available? (class_name)
      begin
        Object.const_get(class_name)
        return true
      rescue
        return false
      end
    end
  end
end


