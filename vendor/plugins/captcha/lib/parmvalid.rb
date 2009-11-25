# ParameterValidator, a keyword argument module for Ruby
# Copyright (C) 2003  Jamis Buck (jgb3@email.byu.edu)
#
# ParameterValidator is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# ParameterValidator is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with ParameterValidator; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# =========================================================================

# ParameterValidator is a mixin module providing parameter validation for
# functions and methods that employ Ruby's "keyword arguments" implemention.
#
# To use it in a class:
#
# * <tt>require 'parmvalid'</tt>
# * <tt>include ParameterValidator</tt>
# * in your method definition, invoke ParameterValidator#validate_parameters,
#   passing in the hash of the actual parameters, and a hash of valid parameters
#   ( name=>default_value pairs, with <tt>default_value==REQUIRED</tt> if the parameter is
#   not optional).  The return value from validate_parameters will be a hash of
#   the parameters, both the optional ones that weren't passed in, and the ones
#   that were.
# * if you want each parameter validated and then set as an instance variable of
#   the class, use validate_and_instantiate_parameters.
# * if you want each parameter validated and then set using similarly-named
#   setters in the class, use validate_and_set_parameters.
#
# Example:
#
#   require 'parmvalid'
#
#   class Demo
#     include ParameterValidator
#
#     def initialize( args )
#       validate_and_instantiate_parameters( args,
#         { :name=>REQUIRED, :date=>Time.now, :location=nil, :memo=>REQUIRED } )
#
#       p @name
#       p @date
#       p @location
#       p @memo
#     end
#   end
#
#   d = Demo.new( :name=>"Jamis", :memo=>"Some memo" )
#
# Author: Jamis Buck (jgb3@email.byu.edu)
module ParameterValidator

  # A unique constant, used as the default value for a parameter to indicate that
  # it is required.
  REQUIRED = Object.new

  # The exception that gets thrown when an invalid parameter is specified.
  class InvalidParameterException < RuntimeError; end

  # The exception that gets thrown when a required parameter is not specified.
  class MissingParameterException < RuntimeError; end

  # Validates a hash of actual parameters (as created by Ruby's pseudo-"keyword
  # arguments" feature) against a list of valid parameters.
  #
  # Parameters:
  # * actual_parms: the hash of actual parameters that were given by Ruby's
  #   pseudo-"keyword arguments" feature.
  # * valid_parameters: the hash of valid parameters, where the key for each entry
  #   in the hash is a symbol naming the acceptable parameter, and the value is the
  #   default value for that parameter.  If the default value for any entry is the
  #   constant REQUIRED, then the parameter must not be absent from the actual_parms
  #   hash.
  #
  # Returns: a hash of all parameters, together with either the actual value that
  # was passed in, or (in the case of optional parameters that were not passed in)
  # the default value.
  def validate_parameters( actual_parms, valid_parms )
    parms = Hash.new

    # set the default values
    valid_parms.each_pair do |key,value|
      next if value == REQUIRED
      parms[ key ] = value
    end

    # set the actual values
    actual_parms.each_pair do |key,value|
      if not valid_parms.include? key
        raise InvalidParameterException, "'#{key}' is invalid"
      end
      parms[ key ] = value
    end

    # check required parameters
    valid_parms.each_pair do |key,value|
      if value==REQUIRED and not parms.include? key
        raise MissingParameterException, "'#{key}' is required"
      end
    end

    parms
  end

  # For each key in the given hash, create an identically-named instance variable
  # and set its value to the value of the given key.
  def instantiate_parameters( parms )
    parms.each_pair do |key, value|
      eval "@#{key} = value"
    end
  end

  # For each key in the given hash, assign its value to an identically-named setter
  # in the current class.
  def set_parameters( parms )
    parms.each_pair do |key, value|
      eval "self.#{key} = value"
    end
  end

  # Validate and instantiate the given parameters by calling both validate_parameters
  # and instantiate_parameters.  Return the hash of all parameters.
  def validate_and_instantiate_parameters( actual_parms, valid_parms )
    parms = validate_parameters( actual_parms, valid_parms )
    instantiate_parameters( parms )
    parms
  end

  # Validate and set the given parameters by calling both validate_parameters
  # and set_parameters.  Return the hash of all parameters.
  def validate_and_set_parameters( actual_parms, valid_parms )
    parms = validate_parameters( actual_parms, valid_parms )
    set_parameters( parms )
    parms
  end
end
