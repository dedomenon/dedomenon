# =========================================================================
# Ruby/CAPTCHA: a module that implements a "Completely Automated Public
#   Turing Test to Tell Computers and Humans Apart"
# Copyright (C) 2003  Jamis Buck (jgb3@email.byu.edu)
#
# Ruby/CAPTCHA is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# Ruby/CAPTCHA is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ruby/CAPTCHA; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# =========================================================================

require 'openssl'
require 'GD'

require 'datename'
require 'parmvalid'

class String
  # this allows a new string to be created that consists of ''n'' random characters
  # of the source string.
  def random( new_length )
    s = ""
    new_length.times { s << self[rand(length),1] }
    s
  end
end

# CAPTCHA stands for "Completely Automated Public Turing Test to Tell Computers and
# Humans Apart."  This module provides classes that allow web sites to use randomly
# generated images, in concert with randomly generated keys and encrypted digests,
# to do such things as preventing automated registrations.
module CAPTCHA

  VERSION = "0.1.2"

  # Determine the default template path. It first checks to see if there is a
  # gem version of Ruby/CAPTCHA installed, and uses that as the base path.
  # If there is no gem installed, it uses /usr/share/captcha/templates.
  def self.default_template_path
    begin
      require 'rubygems'
      matches = Gem.cache.search( "captcha", "=#{VERSION}" )
      return File.join( matches.last.full_gem_path, "/data/captcha/templates" )
    rescue Exception => e
      return "#{RAILS_ROOT}/vendor/plugins/captcha/templates"
    end
  end

  USE_CHARS = "123456789abcdefghijkmnpqrstuvwxyz!@&%$?+ABDEFGHMNQRT"
  FONT = "/usr/share/fonts/truetype/ttf-bitstream-vera/Vera.ttf"
  FONT_SIZE = 32.0
  IMAGE_DIR = "#{RAILS_ROOT}/public/images/captcha/"
  IMAGE_URI = "/images/captcha/"
  CLEAN_UP_INTERVAL = 6.hours
  KEY_LENGTH = 6
  X_SPACING = 15
  Y_WIGGLE = 40
  ROTATION = 20
  TEMPLATE = File.join( default_template_path, "default.html" )

  # A simple rectangle class, to make the bounds returned by the GD::Image#stringFT method
  # more readable.
  class Rectangle
    attr_accessor :x, :y
    attr_accessor :width, :height

    def initialize( x, y, width, height )
      @x, @y = x, y
      @width, @height = width, height
    end

    # This accepts an array of integers, as returned by the GD::Image#stringFT method.
    def Rectangle.from_array( points )
      minx = [ points[0], points[2], points[4], points[6] ].min
      maxx = [ points[0], points[2], points[4], points[6] ].max
      miny = [ points[1], points[3], points[5], points[7] ].min
      maxy = [ points[1], points[3], points[5], points[7] ].max

      x = minx
      y = miny
      width = maxx - minx
      height = maxy - miny

      Rectangle.new( x, y, width, height )
    end
  end

  # An obfuscated image, which draws the letters of a key string at random offsets against
  # a noisy background.
  class ObfuscatedImage < GD::Image
    private_class_method :new

    # this is the only way to create an image of this sort, since 'new' is private.  This
    # is because of the way the Ruby/GD module implements the GD::Image class... you can't
    # override it by providing an 'initialize' method.
    #
    # * key: the key string to display
    # * font: the font to display the key in.  This should be a path to a font file.
    # * font_size: the size (in points) that the key string should be displayed
    # * x_spacing: how much space to insert between characters
    # * max_wiggle_y: the maximum "wiggle" for each character in y
    # * rotation: the maximum angle of rotation for each character.
    def ObfuscatedImage.create( key, font, font_size, x_spacing, max_wiggle_y, rotation )
      width, height = 0, 0

      key.each_byte do |byte|
        char = byte.chr

        err, bounds = GD::Image.stringFT( 0, font, font_size, 0, 0, 0, char )
        raise err if err

        bounds = Rectangle.from_array( bounds )

        width += bounds.width
        height = bounds.height if height < bounds.height
      end

      char_height = height

      extra_x = x_spacing * ( key.length + 1 )
      extra_y = max_wiggle_y

      width += extra_x
      height += extra_y

      image = new( width, height )
      image.initialize_image( key, font, font_size, x_spacing, max_wiggle_y, char_height, rotation )

      return image
    end

    # The 'initialize' method for an ObfuscatedImage.  The parameters are the same
    # as for the #create method, with the addition of char_height (which represents
    # the maximum height of any character in the string).
    def initialize_image( key, font, font_size, x_spacing, wiggle_y, char_height, rotation )
      @key = key
      @font = font
      @font_size = font_size
      @x_spacing = x_spacing
      @wiggle_y = wiggle_y
      @char_height = char_height
      @rotation = rotation

      clear_background
      populate_with_noise
      draw_key
    end

    # clear the image background to white.
    def clear_background
      white = colorResolve( 255, 255, 255 )
      filledRectangle( 0, 0, width, height, white )
    end

    # populate the image with random noise
    def populate_with_noise
      color = colorResolve( 0, 0, 0 )

      ( width * height / 4 ).times do
        x, y = rand( width ), rand( height )
        setPixel( x, y, color )
      end

      inc = height/10
      ( height / inc ).times do |i|
        line( 0, inc*i + rand(20) - 10, width, inc*i + rand(20) - 10, color )
      end
    end

    # draw the key string on the image, randomly positioning each character.
    def draw_key
      black = colorResolve( 0, 0, 0 )
      x = @x_spacing

      @key.each_byte do |b|
        c = b.chr
        y = rand( 3*@wiggle_y/4 ) + @char_height

        # compute the unrotated bounds, for determing how to increment
        err, bounds = GD::Image.stringFT( 0, @font, @font_size, 0, 0, 0, c )
        rect = Rectangle.from_array( bounds )

        # draw the character
        stringFT( black, @font, @font_size,
                  Math::PI*(rand(@rotation)-@rotation/2)/180.0,
                  x, y, c )

        x += rect.width + @x_spacing
      end
    end
  end

  # This class provides a way to use the ObfuscatedImage on a web page, in concert
  # with an encrypted digest and key.
  class Web
    include ParameterValidator

    attr_reader   :key
    attr_reader   :digest

    attr_accessor :font
    attr_accessor :font_size
    attr_accessor :image_dir
    attr_accessor :image_uri
    attr_accessor :clean_up_interval
    attr_accessor :template_file
    attr_accessor :x_spacing
    attr_accessor :y_wiggle
    attr_accessor :rotation

    # the list of variables that may be validly specified in a configuration file, or as
    # an option to 'new'
    VALID_CONFIG_VARS = { :key_length=>KEY_LENGTH,
                          :font=>FONT,
                          :font_size=>FONT_SIZE,
                          :image_dir=>IMAGE_DIR,
                          :image_uri=>IMAGE_URI,
                          :clean_up_interval=>CLEAN_UP_INTERVAL,
                          :template_file=>TEMPLATE,
                          :use_chars=>USE_CHARS,
                          :x_spacing=>X_SPACING,
                          :y_wiggle=>Y_WIGGLE,
                          :rotation=>ROTATION }

    # Create a new Web object, configuring it from the file with the given name.  Any
    # variables not set in the configuration file will be given default values.
    def Web.from_configuration( file_name )
      eval File.open( file_name, "r" ) { |file| file.read }

      options = Hash.new

      ( local_variables - [ "file_name",  "options" ] ).each do |local|
        local_sym = eval( ":#{local}" )
        options[ local_sym ] = eval( local )
      end

      return new( options )
    end

    # Initialize a new Web object with the given values.  The valid parameters are the same
    # as the valid configuration variables (VALID_CONFIG_VARS).
    def initialize( options={} )
      validate_and_instantiate_parameters( options, VALID_CONFIG_VARS )

      @key = @use_chars.random( @key_length )
      @digest = OpenSSL::Digest::MD5.new( @key ).hexdigest
    end

    # Get the name of the image file.  This will generate the file name if it has not
    # yet been generated.
    def file_name
      @file_name = "%08X.png" % [ rand(0xFFFFFFFF) ] if @file_name.nil?
      @file_name
    end

    # Get the ObfuscatedImage that will be shown on the page.  If the image has not yet
    # been created, this will create it.
    def image
      if @image.nil?
        @image = ObfuscatedImage.create( @key, @font, @font_size, @x_spacing, @y_wiggle, @rotation )
        File.open( File.join( @image_dir, file_name ), "w" ) { |file| @image.png file }
      end

      @image
    end

    # Convert the object to HTML, using the given template file name if provided.  If a template
    # is not given here, the one used to configure the object will be used instead.  The template
    # file should contain the following tokens:
    #
    # * %%IMAGE%%: the file name of the image
    # * %%IMAGEURI%%: the web-accessible directory containing the image
    # * %%DIGEST%%: the digest string
    # * %%IMAGEWIDTH%%: the width of the image file
    # * %%IMAGEHEIGHT%%: the height of the image file
    def to_html( template_file=nil )
      template = File.open( ( template_file || @template_file ), "r" ) { |file| file.read }

      template.gsub( /%%IMAGE%%/, file_name ).
               gsub( /%%IMAGEURI%%/, @image_uri ).
               gsub( /%%DIGEST%%/, @digest ).
               gsub( /%%IMAGEWIDTH%%/, image.width.to_s ).
               gsub( /%%IMAGEHEIGHT%%/, image.height.to_s )
    end

    # Look in the image directory, deleting any images there that are more than
    # 'clean_up_interval' seconds old.
    def clean
      Dir.foreach( @image_dir ) do |entry|
        next if entry !~ /\.png$/
        if Time.now - File.stat( File.join( @image_dir, entry ) ).mtime > @clean_up_interval
          File.delete( File.join( @image_dir, entry ) )
        end
      end
    end

    # Test the given key against the given digest.  If the digest was created from the given
    # key, return true, otherwise return false.
    def Web.is_valid( key, digest )
      new_digest = OpenSSL::Digest::MD5.new( key ).hexdigest
      return ( digest == new_digest )
    end
  end

end
