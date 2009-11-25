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

# *Description*
#     This class represents an acocunt in the myowndb system
# An account is either paid account or free account
# containnig many databases and users.
#
# *Fields*
#      This model has following fields:
#
# * id
# * account_type_id
# * name
# * street
# * zip_code
# * city
# * country
# * status
# * end_date
# * subscription_id:          see ticket #41
# * subscription_gateway      
# * vat_number
# * attachment_count
# 
# *Relations*
#    * has_many :databases,  :class_name => "Database"
#    * has_many :users
#    * has_many :invoices
#    * has_many :transfers
#    * belongs_to :account_type
#    * belongs_to :upgrade_to, :class_name => "AccountType", :foreign_key => "upgrade_id"
#
# *Validations*
#    * validates_presence_of :name, :message => "madb_enter_account_name"
#    * validates_size_of :country, :minimum => 2, :message => "madb_choose_country"
class Account < ActiveRecord::Base
  
  
  
  has_many :databases,  :class_name => "Database"
  has_many :users
  belongs_to :account_type
  belongs_to :upgrade_to, :class_name => "AccountType", :foreign_key => "upgrade_id"
  validates_presence_of :name, :message => "madb_enter_account_name"
  validates_size_of :country, :minimum => 2, :message => "madb_choose_country"
  
  attr_readonly   :id
  attr_protected  :active, 
                  :allows_download,
                  :allows_login,
                  :allows_transfer,
                  :allows_upload,
                  :expired,
                  :transfer_percentage_this_month,
                  :transfers_this_month,
                  :vat,
                  :users_url,
                  :databases_url
  
  

  #alias to_json old_to_json
      # Returns whether account is active or inactive.
  def active?
    status == "active"
  end

  # *Description*
  #     Returns whether the current account object allows
  # Loging in or not?
  #
  # *Workflow*
  #     If the account type is free, returns true. Otherwise the
  # end_date field is compared with the todays date and the
  # status is checked to be active or cancelled. If the end_date
  # is ahead of the date today and the account status is active or
  # cancelled, returns true.
  def allows_login?
    return true if account_type.name=="madb_account_type_free"
    begin
      if end_date > Date.today and ["active", "cancelled"].include? status
          return true
      end
    rescue Exception
    end

    return false
  end

  # *Description*
  #     Returns whether the account is expired or not.
  # *Workflow*
  #     status field is compared to "expired" and result is returned.
  def expired?
    status=="expired"
  end

  # *Description*
  #     Returns the value added tax for the account.
  # *Workflow*
  #     * If <tt>country</tt> field is "Belgium" then 21
  #     * Otherwise if <tt>country</tt> is in EU but no vat number then 21 otherwise 0
  #     * Outside EU, 0

  def vat
    # always 21% in belgium
    if country=="Belgium"
      return 21
    end

    #in european union: 21 for individuals, 0 for companies
    if MadbSettings.european_countries.include? country
      if vat_number.nil? or vat_number==''
        return 21
      else
        return 0
      end
    end

    # 0 outside EU
    return 0
  end

      
#  #FIXME: Add the options behaviour as a standard behaviour
#  #FIXME: When the initial string is null, should proceed next.
#  #FIXME: Now this is calling some methods which are basically moved to 
#  #       s3_attachment plugin. Rewrite this!
#  def to_json(options={})
#    
#    json = JSON.parse(super(options))
#    format = ''
#    format = '.' + options[:format] if options[:format]
#    
#    replace_with_url(json, 'id', :Account, options)
#    replace_with_url(json, 'account_type_id', :AccountType, options)
#    
#    json['active']                          = active?
#    #json['allows_download']                 = allows_download?
#    json['allows_login']                    = allows_login?
#    #json['allows_transfer']                 = allows_transfer?
#    #json['allows_upload']                   = allows_upload?
#    json['expired']                         = expired?
#    #json['transfer_percentage_this_month']  = transfer_percentage_this_month
#    #json['transfers_this_month']            = transfers_this_month
#    json['vat']                             = vat
#    
#    
#    json['users_url'] = (@@lookup[:Account] % [@@base_url, self.id])
#    json['users_url'] += (@@lookup[:User] % ['', '']).chop + format
#    
#    json['databases_url'] = (@@lookup[:Account] % [@@base_url, self.id])
#    json['databases_url'] += (@@lookup[:Database] % ['', '']).chop + format
#    
#    return json.to_json
#    
#    
#    
#
#  end
end
