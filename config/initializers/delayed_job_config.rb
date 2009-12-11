Delayed::Job.class_eval do
  class << self
    alias :db_time_now_ori :db_time_now
    def db_time_now
      (ActiveRecord::Base.default_timezone == :utc) ? Time.now.utc : Time.zone.now
      rescue NoMethodError
        Time.now 
    end
  end
end

Delayed::Job.destroy_failed_jobs = false
silence_warnings do
  Delayed::Job.const_set("MAX_ATTEMPTS", 3)
  Delayed::Job.const_set("MAX_RUN_TIME", 5.minutes)
end
