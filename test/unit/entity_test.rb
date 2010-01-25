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

class EntityTest < ActiveSupport::TestCase
  self.use_transactional_fixtures = false
  fixtures :entities, :data_types, :details, :entities2details, :instances, :detail_values, :integer_detail_values, :date_detail_values, :ddl_detail_values, :detail_value_propositions

  def setup
    @entity = Entity.find(12)
  end

  def test_ordered_details
    assert_equal  @entity.details.sort{|a,b| a.display_order<=>b.display_order},  @entity.ordered_details
    assert_equal ["nom", "prenom", "fonction", "service", "coordonees_specifiques", "company_email"], @entity.ordered_details.map{|d| d.name}
  end
  
  def test_list_details
    assert_equal  5, @entity.details_in_list_view.size
    assert_equal ["nom", "prenom", "fonction", "service", "company_email"], @entity.details_in_list_view.map{|d| d.name}
  end

  #{ "status"=>   {  "0"=>  {"id"=>"18", "value"=>"11"}  },
  #   "nom"=>     {  "0"=>  {"id"=>"347", "value"=>"Axios"}  },
  #  "entity"=>   "11", 
  #  "memo"=>     {  "0"=>  {"id"=>"353", "value"=>""}  },
  #  "company_email"=>  {  "0"=>  {"id"=>"354", "value"=>"fdfsd.com"} },
  #  "instance_id"=>"77",  
  #  "code_nace"=>  {"0"=>  {"id"=>"348", "value"=>"230202020"}  },
  #  "fax"=>  {"0"=>  {"id"=>"352", "value"=>"+32 2 227 61 01"}  },
  #  "adresse"=>  {"0"=>{"id"=>"350", "value"=>"Place De Brouckere 26"}},
  #  "telephone"=>{"0"=>{"id"=>"351", "value"=>"+32 2 227 61 00"}},
  #  "TVA"=>{"0"=>{"id"=>"349", "value"=>"BE230202020"}},
  #  "personnes_occuppees"=>{"0"=>{"id"=>"8", "value"=>"eight"}}
  #}
  def test_instanciation
    dv_count_before = DetailValue.count
    i, invalid_fields = Entity.instanciate(12, "nom" => "Dupont", "prenom" => "Charles", "fonction" => "Directeur", "coordonees_specifiques" => "ZGS", "company_email" => "cd@dupont.com")
    dv_count_after = DetailValue.count
    assert_not_nil i
    assert_equal invalid_fields, []
    assert_equal i.get("nom"), ["Dupont"]
    assert_equal i.get("prenom"), ["Charles"]
    assert_equal i.get("fonction"), ["Directeur"]
    assert_equal i.get("coordonees_specifiques"), ["ZGS"]
    assert_equal i.get("company_email"), ["cd@dupont.com"]
    assert_equal dv_count_after-dv_count_before, 5

    # is ok, some detail_values unspecified and left empty
    dv_count_before = DetailValue.count
    i, invalid_fields = Entity.instanciate(12, "nom" => "Dupont", "prenom" => "Charles", "company_email" => "cd@dupont.com")
    dv_count_after = DetailValue.count
    assert_not_nil i
    assert_equal invalid_fields, []
    assert_equal i.get("nom"), ["Dupont"]
    assert_equal i.get("prenom"), ["Charles"]
    assert_equal i.get("fonction"), []
    assert_equal i.get("coordonees_specifiques"), []
    assert_equal i.get("company_email"), ["cd@dupont.com"]
    assert_equal dv_count_after-dv_count_before, 3
    
    # is ok, unknown details are ignored
    dv_count_before = DetailValue.count
    i, invalid_fields = Entity.instanciate(12, "nom" => "Dupont", "prenom" => "Charles", "company_email" => "cd@dupont.com", "inexisting_detail" => "my value")
    dv_count_after = DetailValue.count
    assert_not_nil i
    assert_equal invalid_fields, []
    assert_equal i.get("nom"), ["Dupont"]
    assert_equal i.get("prenom"), ["Charles"]
    assert_equal i.get("fonction"), []
    assert_equal i.get("coordonees_specifiques"), []
    assert_equal i.get("company_email"), ["cd@dupont.com"]
    assert_equal dv_count_after-dv_count_before, 3
    # is NOT ok, invalid email address
    dv_count_before = DetailValue.count
    i_count_before = Instance.count
    i, invalid_fields = Entity.instanciate(12, "nom" => "Dupont", "prenom" => "Charles", "company_email" => "cddupont.com")
    dv_count_after = DetailValue.count
    i_count_after = Instance.count
    assert_nil i
    assert_equal i_count_before,i_count_after
    assert_equal ["_contacts_company_email[0]_value"], invalid_fields

    #No details saved raises an exception
    dv_count_before = DetailValue.count
    i_count_before = Instance.count
    assert_raise RuntimeError do
      Entity.instanciate(12, "nomgsdgd" => "Dupont", "pgdsfgsdrenom" => "Charles", "compgsfdgdsany_email" => "cddupont.com")
    end
    dv_count_before = DetailValue.count
    i_count_before = Instance.count
    assert_equal i_count_before,i_count_after
    assert_equal dv_count_before,dv_count_after
    
    
    
    #check ddl and integer types
    dv_count_before = DetailValue.count
    i_count_before = Instance.count
    iv_count_before = IntegerDetailValue.count
    ddlv_count_before = DdlDetailValue.count
    i, invalid_fields = Entity.instanciate( 11, "nom" => "Datatank", "personnes_occuppees" => 25, "memo" => "test", "status" => "sa" )
    dv_count_after = DetailValue.count
    i_count_after = Instance.count
    iv_count_after = IntegerDetailValue.count
    ddlv_count_after = DdlDetailValue.count
    assert_equal [], invalid_fields
    assert_not_nil i
    assert_equal 1, i_count_after-i_count_before
    assert_equal 1, iv_count_after-iv_count_before
    assert_equal 2, dv_count_after-dv_count_before
    assert_equal 1, ddlv_count_after-ddlv_count_before
    assert_equal ["sa"], i.get("status")
    assert_equal [25], i.get("personnes_occuppees")
    
   #add test for invalid values for ddldetails 
    dv_count_before = DetailValue.count
    i_count_before = Instance.count
    iv_count_before = IntegerDetailValue.count
    ddlv_count_before = DdlDetailValue.count
    i, invalid_fields = Entity.instanciate( 11, "nom" => "Datatank", "personnes_occuppees" => 25, "memo" => "test", "status" => "invalid data" )
    dv_count_after = DetailValue.count
    i_count_after = Instance.count
    iv_count_after = IntegerDetailValue.count
    ddlv_count_after = DdlDetailValue.count
    assert_equal ["_societe_status[0]_value"], invalid_fields
    assert_nil i
    assert_equal 0, i_count_after-i_count_before
    assert_equal 0, iv_count_after-iv_count_before
    assert_equal 0, dv_count_after-dv_count_before
    assert_equal 0, ddlv_count_after-ddlv_count_before
    
    #check date types
    dv_count_before = DetailValue.count
    date_count_before = DateDetailValue.count
    i_count_before = Instance.count
    iv_count_before = IntegerDetailValue.count
    ddlv_count_before = DdlDetailValue.count
    i, invalid_fields = Entity.instanciate( 19, "date" => "2009-02-01", "titre" => "test date value" )
    dv_count_after = DetailValue.count
    date_count_after = DateDetailValue.count
    i_count_after = Instance.count
    iv_count_after = IntegerDetailValue.count
    ddlv_count_after = DdlDetailValue.count
    assert_equal [], invalid_fields
    assert_not_nil i
    assert_equal 1, i_count_after-i_count_before
    assert_equal 0, iv_count_after-iv_count_before
    assert_equal 1, dv_count_after-dv_count_before
    assert_equal 0, ddlv_count_after-ddlv_count_before
    assert_equal 1, date_count_after-date_count_before
    assert_equal [DateTime.parse("Sun Feb 01 00:00:00 +0100 2009")], i.get("date")
  end
  
end
