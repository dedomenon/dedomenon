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
require 'entities_controller'

class DetailValueTest < ActiveSupport::TestCase
  fixtures :details, :detail_values

  def setup
    @url_value = DetailValue.find(233)  
    @email_detail_value = DetailValue.find(232)
    # Because URL type is no more a core type.
    #@s3_detail_value = DetailValue.find(234)
  end

  def test_type
    assert_kind_of WebUrlDetailValue, @url_value
    assert_kind_of EmailDetailValue, @email_detail_value
    # Because its no more a core type.
    #assert_kind_of S3Attachment, @s3_detail_value
  end

  def test_html_format
    assert_equal  %q{<a TARGET="_blank" href="http://www.raphinou.com">http://www.raphinou.com</a>},  @url_value.class.format_detail(:value => @url_value.value, :format => :html)
    assert_equal  %q{<a href="mailto:rb@raphinou.com">rb@raphinou.com</a>},  EmailDetailValue.format_detail(:value => @email_detail_value.value, :format => :html)
    #assert_equal  %q{<a href="http://">rb@raphinou.com</a>},  @s3_detail_value.class.format_detail(:value => @s3_detail_value, :controller => @entities_controller, :format => :html)
  end

  def test_csv_format
    assert_equal  %q{http://www.raphinou.com},  @url_value.class.format_detail(:value => @url_value.value, :format => :csv)
    assert_equal  %q{rb@raphinou.com},  EmailDetailValue.format_detail(:value => @email_detail_value.value, :format => :csv)
  end

  def test_default_format
    #debugger
    assert_equal  %q{<a TARGET="_blank" href="http://www.raphinou.com">http://www.raphinou.com</a>},  @url_value.class.format_detail(:value => @url_value.value)
    assert_equal  %q{<a href="mailto:rb@raphinou.com">rb@raphinou.com</a>},  EmailDetailValue.format_detail(:value => @email_detail_value.value)
  end
  
end
