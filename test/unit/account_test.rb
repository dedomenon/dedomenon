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

require File.dirname(__FILE__) + '/../test_helper'

class AccountTest < ActiveSupport::TestCase
  fixtures :account_types, :accounts,:user_types, :users

  def setup
     @account = Account.find(1)
  end
  def test_vat
    #21% for customers in EU without VAT number
    @account.vat_number = nil
    MadbSettings.european_countries.each do |country|
      @account.country = country
      assert_equal 21, @account.vat
    end


    #0% for customers in EU except Belgium with VAT number
    @account.vat_number = "432.546.543"
    c = MadbSettings.european_countries
    c.delete "Belgium"
    c.each do |country|
      @account.country = country
      assert_equal 0, @account.vat
    end

    #21% for customers in Belgium with VAT number
    @account.country = "Belgium"
    assert_equal 21, @account.vat


    #0% for all others
    @account.vat_number = nil
    @account.country = "United States"
    assert_equal 0, @account.vat

    @account.vat_number = "filled"
    @account.country = "United States"
    assert_equal 0, @account.vat
  end


  def test_allows_login_when_no_end_date
     
     #refuse logins for paying accounts without end date
     @account = Account.find(1) #account_type_id = 5
     @account.end_date = nil
     assert  !@account.allows_login?

     #accept logins for free accounts without end date
     free_account = AccountType.find_by_name("madb_account_type_free")
     @account.account_type= free_account 
     @account.save
     assert  @account.allows_login?
  end

  def test_allows_login_for_cancelled_accounts
     
    #accept logins when end_date is in the futur
     @account.status = 'cancelled'
     @account.end_date = Date.today.to_time.next_month.to_date
     @account.save
     assert  @account.allows_login?

     #refuse logins when end_date is passed
     @account.end_date = Date.today.to_time.last_month.to_date
     @account.save
     assert  !@account.allows_login?
  end
  
end
