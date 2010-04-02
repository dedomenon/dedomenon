class String
  def madb_sanitize
    return self if ["id"].include? self
    s= "acc_"+ Digest::SHA1.hexdigest(self)
    return s
  end
end


# We overwrite this for CrosstabObject serialisation
module ActiveRecord #:nodoc:
  module Serialization
      class Serializer #:nodoc:
         def serializable_record
            returning(serializable_record = {}) do

              serializable_names.each { |name| serializable_record[name] = @record.send( (@record.class.to_s == "CrosstabObject") ? name.madb_sanitize : name) }
              add_includes do |association, records, opts|
                if records.is_a?(Enumerable)
                  serializable_record[association] = records.collect { |r| self.class.new(r, opts).serializable_record }
                else
                  serializable_record[association] = self.class.new(records, opts).serializable_record
                end
              end
            end
          end
      end
  end
end

