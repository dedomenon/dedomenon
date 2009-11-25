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

class CrosstabObjectTest < Test::Unit::TestCase
  # The fixtures for the cross_tab objects do not exists.
  # The cross_tab object is being used for a specific purpose
  # and has no role beneath the surface.
  #fixtures :crosstab_objects

  def setup
    #@crosstab_object = CrosstabObject.find(1)
    @crosstab_object = CrosstabObject.new
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of CrosstabObject,  @crosstab_object
  end
end
