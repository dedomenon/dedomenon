
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

require 'digest/sha1'
# *Description*
#   This class models a user in the MyOwnDB system. A user belongs to a single
#   account and has a certian user type.
#   
# *Fields*
#   Has follwing fields:
#     * id
#     * account_id
#     * user_type_id
#     * login
#     * password
#     * email
#     * firstname
#     * lastname
#     * uuid
#     * salt
#     * verified
#     * created_at
#     * updated_at
#     * logged_in_at
# 
# *Relationships*
#   Has following relationships:
#     * belongs_to :account
#     * belongs_to :user_type
#     * has_one :preference
#
# *Validations*
#   * validates_presence_of :password, :password_confirmation, :on => :create, :message => "madb_password_and_confirmation_needed"
#   * validates_presence_of :login_confirmation, :on => :create, :message => " madb_login_not_confirmed"
#   * validates_confirmation_of :password, :message => "madb_password_not_confirmed"
#   * validates_associated :account, :message => "madb_error_in_account"
#   * validates_each :password
#   * validates_confirmation_of
  
class User < ActiveRecord::Base
  
  
  belongs_to :account
  belongs_to :user_type
  has_one :preference
  
  attr_readonly   :id,
                  :account_id
  
  attr_protected :user_type_url,
                 :account_url,
                 :url

  # *Description*
  #   Validates whether current user is an admin or not.
  #
  def admin_user?
    user_type_id==1
  end

  # *Description*
  #   Returns the user with the specified login and password nil otherwise.
  def self.authenticate(login, pass)
    u = User.find(:first, :conditions => ["login = ? AND verified = 1", login])
    
    
    
    if u.nil?
       return nil
    end
    
    
    find(:first, :conditions => ["login = ? AND password = ? AND verified = 1", login, salted_password(u.salt, hashed(pass))])
  end

  # *Description*
  #   Changes the passsword to the specified password.
  def change_password(pass)
    update_attribute("salt", self.class.hashed("salt-#{Time.now}"))
    update_attribute("password", self.class.salted_password(salt, self.class.hashed(pass)))
  end
    
  # *Description*
  #   Returns a randomly generated passwrod.
  def makepass
    chars = ("a".."z").to_a + (1..9).to_a
    chars = chars.sort_by { rand }
    s = chars[0..7].to_s
  end

  # *Description*
  #   Verifies an un verified user.
  def verify
    update_attribute("verified", 1)
  end

  # *Description*
  #   Changes the login to the address given
  def login=(address)
    write_attribute("login", address.downcase)
    write_attribute("email", address.downcase)
  end

  # *Description*
  #   Returns the login name
  #
  def login
    read_attribute("email")
  end

  protected

  
  def self.hashed(str)
    return Digest::SHA1.hexdigest("change-me--#{str}--")[0..31]
  end

  before_create :generate_uuid, :crypt_password
  
  def crypt_password
    RAILS_DEFAULT_LOGGER.info('running encrypt_password')
    #work around needed as cryt_password is called twice in production environment
    return if @encrypted
    @encrypted=true
    write_attribute("salt", self.class.hashed("salt-#{Time.now}"))
    write_attribute("password", self.class.salted_password(salt, self.class.hashed(password)))
  end

  def generate_uuid
    self.uuid = self.class.hashed("uuid-#{Time.now}")
  end

  def self.salted_password(salt, hashed_password)
    hashed(salt + hashed_password)
  end

#  validates_length_of :login, :within => 6..40, :message => "madb_login_too_short"
  validates_each :login, :on => :create  do |record, attr, value|

    if value.length>0
      if value.length<6
        record.errors.add attr, 'madb_login_too_short'
      end
      if !value.match(/^[_\w-]+(\.[_\w-]+)*@[\w-]+(\.\w+)*(\.[a-z]{2,4})$/)
        record.errors.add attr, 'madb_login_not_a_valid_email'
      end
      #if User.count(["login = ?", value])>0 is DEPRECATED
      if User.count(:login, :conditions => ["login = ?", value]) > 0
        record.errors.add attr, 'madb_login_already_taken'
      end
    else
        record.errors.add attr, 'madb_login_cannot_be_blank'
    end

  end
#  validates_format_of :login, :with =>/^[_\w-]+(\.[_\w-]+)*@[\w-]+(\.\w+)*(\.[a-z]{2,3})$/ 
  #validates_uniqueness_of :login
  validates_confirmation_of :login, :on => :create, :message => "madb_login_not_confirmed"

  #validates_length_of :password, :within => 6..40, :message => "madb_password_too_short"
  validates_each :password do |record, attr, value|
      if value.length<5
        record.errors.add attr, 'madb_password_too_short'
      end
      if value.length>40
        record.errors.add attr, 'madb_password_too_long'
      end
  end
#  validates_presence_of :login
  validates_presence_of :password, :password_confirmation, :on => :create, :message => "madb_password_and_confirmation_needed"
  validates_presence_of :login_confirmation, :on => :create, :message => " madb_login_not_confirmed"
  validates_confirmation_of :password, :message => "madb_password_not_confirmed"
  validates_associated :account, :message => "madb_error_in_account"
  
#  public
#  def to_json(options = {})
#    json = JSON.parse(super(options))
#    
#    # These items should not be returned!
#    json.delete 'password'
#    json.delete 'salt'
#    json.delete 'auth_key'
#    json.delete 'auth_key_id'
#    
#    replace_with_url(json, 'id', :User, options)
#    replace_with_url(json, 'account_id', :Account, options)
#    replace_with_url(json, 'user_type_id', :UserType, options)
#    
#    return json.to_json
#  end

end
