# =========================================================================
# datename.rb: a Ruby extension for easy date unit conversion
# Copyright (C) 2003  Jamis Buck (jgb3@email.byu.edu)
#
# datename.rb is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# datename.rb is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with datename.rb; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# =========================================================================

# Modify the Time class to provide methods for converting a given number
# of date units (like years, weeks, and days) to seconds.
class Time
  def Time.years( num )
    num * Time.days( 365 )
  end

  def Time.weeks( num )
    num * Time.days( 7 )
  end

  def Time.days( num )
    num * Time.hours( 24 )
  end

  def Time.hours( num )
    num * Time.minutes( 60 )
  end

  def Time.minutes( num )
    num * Time.seconds( 60 )
  end

  def Time.seconds( num )
    num
  end
end

# Modify the Numeric class for providing a series of methods that allow
# date units to be converted to seconds easily, like "2.weeks".
class Numeric
  def Numeric.time_alias( name )
    class_eval <<-EOF
      def #{name}
        Time.#{name}( self )
      end
    EOF
  end

  time_alias :years
  time_alias :weeks
  time_alias :days
  time_alias :hours
  time_alias :minutes
  time_alias :seconds

  alias :year   :years
  alias :week   :weeks
  alias :day    :days
  alias :hour   :hours
  alias :minute :minutes
  alias :second :seconds
end
