################################################################################
#This file is part of Dedomenon.
#
#Dedomenon is free software: you can redistribute it and/or modify
#it under the terms of the GNU Affero General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#Dedomenon is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU Affero General Public License for more details.
#
#You should have received a copy of the GNU Affero General Public License
#along with Dedomenon.  If not, see <http://www.gnu.org/licenses/>.
#
#Copyright 2008 Raphaël Bauduin
################################################################################

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes     = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils        = true

# Enable the breakpoint server that script/breakpointer connects to
#config.breakpoint_server = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = true

#user sendmail command to send mail
#ActionMailer::Base.delivery_method=:sendmail
class MadbSettings
  #per environment: self.list_length
  def self.list_length
    30
  end
  # For the development mode, we store the files in the tmp directory.
  def self.s3_local_dir
    "#{RAILS_ROOT}/tmp/files"
  end
  def self.s3_bucket_name
    "madb_devel"
  end

end



#require 'paypal'
#Paypal::Notification.ipn_url = "https://www.sandbox.paypal.com/cgi-bin/webscr"

require 'ruby-debug'
Debugger.start
