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
#   Issues notificaions of differnet sort. 
# PENDING: Document all the methods.
class Notify < ActionMailer::Base
  def signup(user, password='<what you entered on the website>', url=nil, options ={} )
    
    options = { :sent_on=>Time.now}.update options 
    @body["lang"] = options[:lang]||"en"

    
    # Email header info
    @recipients = "#{user.login}"
    @from       = CONFIG['email_from'].to_s
    @subject    = t("madb_welcom_to_madb_signup_subject", :lang => options[:lang] )
    @sent_on    = sent_on

    # Email body substitutions
    @body["name"] = "#{user.firstname} #{user.lastname}"
    @body["login"] = user.login
    @body["password"] = password
    @body["url"] = url || CONFIG['app_url'].to_s
    @body["uuid"] = user.uuid

  end

  def paying_signup(user, url=nil, options ={} )
    
    options = { :sent_on=>Time.now}.update options 
    @body["lang"] = options[:lang]||"en"

    
    # Email header info
    @recipients = "#{user.login}"
    @from       = CONFIG['email_from'].to_s
    @subject    = t("madb_welcom_to_madb_signup_subject", :lang => options[:lang] )
    @sent_on    = sent_on

    # Email body substitutions
    @body["name"] = "#{user.firstname} #{user.lastname}"
    @body["login"] = user.login
    @body["url"] = url || CONFIG['app_url'].to_s
    @body["uuid"] = user.uuid

  end

  def account_expired(users, url=nil, options ={} )
    
    options = { :sent_on=>Time.now}.update options 
    @body["lang"] = options[:lang]||"en"

    
    # Email header info
    @recipients = users.collect{|u| u.login}
    @from       = CONFIG['email_from'].to_s
    @subject    = t("madb_eot_subject", :lang => options[:lang] )
    @sent_on    = sent_on

    # Email body substitutions
    @body["url"] = url || CONFIG['app_url'].to_s

  end
  def forgot_password(user, password, url=nil, options={})
    
    options = { :sent_on=>Time.now}.update options 
    @body["lang"] = options[:lang]||"en"
    @user = user
    
    # Email header info
    @recipients = "#{user.login}"
    @from       = CONFIG['email_from'].to_s
    @subject    = t("madb_forgot_password_subject", :lang => options[:lang] )
    @sent_on    = options[:sent_on]

    # Email body substitutions
    @body["name"] = "#{user.firstname} #{user.lastname}"
    @body["login"] = user.login
    @body["password"] = password
    @body["url"] = url || CONFIG['app_url'].to_s
    @body["lang"] = options[:lang]
  end

  def change_password(user, password, url=nil, language='en', sent_on=Time.now)
    # Email header info
    @recipients = "#{user.login}"
    @from       = CONFIG['email_from'].to_s
    @subject    = t("madb_change_password_subject", :lang => language )
    @sent_on    = sent_on

    # Email body substitutions
    @body["name"] = "#{user.firstname} #{user.lastname}"
    @body["login"] = user.login
    @body["password"] = password
    @body["language"] = language 
    @body["url"] = url || CONFIG['app_url'].to_s
  end
end
