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

require 'breakpoint'
require 'log4r'
include Log4r

$destination_environment = ARGV[2] || "production"
$source_environment = ARGV[1] || "translate"


#Initialise loggers
#for exceptions and errors
@main_logger=Logger.new("#{RAILS_ROOT}/log/translations_transfer.rb")

#for translations created
@new_translations_logger=Logger.new("#{RAILS_ROOT}/log/translations_transfer_new.log")

#for translations updated
@updated_translations_logger=Logger.new("#{RAILS_ROOT}/log/translations_transfer_updates.log")

class SourceTranslation < ActiveRecord::Base
  establish_connection(
    $source_environment+"-translations"
  )
  set_table_name "translations"
  def self.reloadable?; false end
end

class DestinationTranslation < ActiveRecord::Base
  record_timestamps = false
  establish_connection(
    $destination_environment+"-translations"
  )
  set_table_name "translations"
  def self.reloadable?; false end
end

  def sanitize_backtrace(trace)
    re = Regexp.new(/^#{Regexp.escape(RAILS_ROOT)}/)
    trace.map do |line|
        Pathname.new(line.gsub(re,"[RAILS_ROOT]")).cleanpath.to_s
    end
  end


#iterated on all source translations
SourceTranslation.find(:all, :conditions => "scope='system'").each do |s|
  begin
    destination_translations = DestinationTranslation.find(:all, :conditions => [ "t_id=? and lang=? and scope = 'system'", s.t_id, s.lang ])
    #if we find more than one translation in the destination db, we have a problem
    if destination_translations.length>1
       @main_logger.info "multiple destination translations for #{s.t_id}  in #{s.lang}" 
       next
    end
    #if we find on translation, we are in a possible update case
    if destination_translations.length>0
      d = destination_translations[0]

      #if the update of the destination is earlier than the source, we need to update
      if d.updated_at < s.updated_at
        @updated_translations_logger.info %{ #{d.t_id} in #{d.lang} updated from value #{d.value} to #{ s.value} }
        d.value = s.value
        d.id_filter = s.id_filter
        d.save
      #if the update of the destination is later or equal than the source, we have an up to date translation
      else
        @main_logger.info  %{translations #{d.t_id} in #{d.lang} is up to date}
      end
    # if we don't find a destination translation, we need to create it
    else
      d=DestinationTranslation.new(:t_id => s.t_id, :lang => s.lang, :value => s.value, :scope => s.scope, :id_filter => s.id_filter)
      d.save
      @new_translations_logger.info %{ #{s.t_id} in #{s.lang} created with value #{s.value}}
    end
  rescue Exception => e
    @main_logger.info "Exception with #{s.t_id} in #{s.lang}:\n #{e.to_s} \n #{sanitize_backtrace(e.backtrace)}"
  end

end
