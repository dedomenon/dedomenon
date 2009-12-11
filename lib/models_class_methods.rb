#this needs to be in the lib directory so that it can be loaded when ad plugin adds an observer to Instance
#it was initially in the config/initializers directory, but caused trouble
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


