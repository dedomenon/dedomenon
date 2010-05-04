
#!/usr/bin/env ruby

# Jobs should not be older than 1 hour
old_jobs = Delayed::Job.count(:conditions => [ 'created_at < ?', Time.now - 1.hour])

if old_jobs > 0
  # Notify admin
  Notify.deliver_admin("test", "body")
end

