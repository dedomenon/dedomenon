require 'rubygems'
require 'yaml'

namespace :madb do
  desc "Monitor Delayed Job queue and notify admin if there are jobs older than 1 hour"
  task :monitor_dj => :environment do
    old_jobs = Delayed::Job.count(:conditions => [ 'created_at < ?', Time.now - 1.hour])
    if old_jobs > 0
      # Notify admin
      Notify.deliver_admin("Old jobs in Delayed Job queue", "There are jobs older than one hour in the queue!")
    end
  end
end
