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

class InstanceTest < ActiveSupport::TestCase
  fixtures :instances, :entities, :details, :entities2details

  def setup
    @instance = Instance.find(25)
  end

  def test_details_hash

    expected_value= {"email_detail"=>Detail.find(23), "Rue"=>Detail.find(37), "company_name"=>Detail.find(35), "legal_status"=>Detail.find(36), "Ville"=>Detail.find(38), "Code_postal"=>Detail.find(39), "s3_detail"=>Detail.find(25)}
    assert_equal @instance.details_hash, expected_value
  end

  def test_get
    instance = Instance.find 85
    assert_equal instance.get("nom"), ["Brughmans"]
    assert_equal instance.get("prenom"), ["Raphaël"]
    assert_equal instance.get("fonction"), ["Informaticien"]
    assert_equal instance.get("company_email"), ["raphael.brughmans@bardaf.be"]
    assert_equal instance.get("blurps"), []

    #test ddl details
    instance = Instance.find 77
    assert_equal instance.get("status"), ["sprl"]

    #test date details
    instance = Instance.find 95
    assert_equal [DateTime.parse("Sat Sep 10 00:00:00 +0200 2005")], instance.get("date")

    #test integer details
    instance = Instance.find 77
    assert_equal [10], instance.get("personnes_occuppees")

    # request detail_value instance
    instance = Instance.find 85
    assert_equal instance.get("nom", :type => :detail_value), [ DetailValue.find(403) ]
    assert_equal instance.get("prenom", :type => :detail_value), [DetailValue.find(404)]
    assert_equal instance.get("fonction", :type => :detail_value), [DetailValue.find(405)]
    assert_equal instance.get("company_email", :type => :detail_value), [DetailValue.find(408)]
    assert_equal instance.get("blurps", :type => :detail_value ), []

    #test ddl details
    instance = Instance.find 77
    assert_equal instance.get("status", :type => :detail_value), [DdlDetailValue.find(18)]

    #test date details
    instance = Instance.find 95
    assert_equal [DateDetailValue.find(44)], instance.get("date", :type => :detail_value)
    
    #test integer details
    instance = Instance.find 77
    assert_equal [IntegerDetailValue.find(8)], instance.get("personnes_occuppees", :type => :detail_value)


  end
end
