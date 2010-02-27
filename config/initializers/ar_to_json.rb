class String
  def madb_sanitize
    s = self.downcase.gsub(/[ ?!.-\/]/, "_").gsub(/ /,"_")
    if s==""
      s=ActiveSupport::JSON::Encoding.escape(name).gsub(/"/, "").gsub(/\\/,"")
    end
    return s
  end
end


module ActiveRecord #:nodoc:
  module Serialization
      class Serializer #:nodoc:
         def serializable_record
            returning(serializable_record = {}) do
              serializable_names.each { |name| serializable_record[name] = @record.send(name.madb_sanitize) }
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

