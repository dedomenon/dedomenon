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

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger        = SyslogLogger.new


# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors if you bad email addresses should just be ignored
# config.action_mailer.raise_delivery_errors = false
class MadbSettings
  #per environment: self.list_length
  def self.list_length
    30
  end
  def self.s3_local_dir
    "#{RAILS_ROOT}/var/files"
  end
  def self.s3_bucket_name
    "madb_devel"
  end

end



#FIXME: PayPal stuff is yet disabled
#require 'paypal'
#Paypal::Notification.ipn_url = "https://www.paypal.com/cgi-bin/webscr"
#Paypal::Notification.paypal_cert = File::read("#{RAILS_ROOT}/config/environments/production_paypal_cert.pem")

#require 'payment_data'
#Paypal::PaymentData.pdt_url = "https://www.paypal.com/cgi-bin/webscr"
#Paypal::PaymentData.identity_token = "XW3IYGbzEjZ0L-w7mN8jPUMqym-NGDC92P-OC47Ph2_hczDx4nQo_EXPP7W"
