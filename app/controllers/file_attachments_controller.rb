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
#   This controller handlles the downloading of files.
#
class FileAttachmentsController < ApplicationController

  def initialize

  end

  # *Description*
  #   This allows you to download an attachment.
  #   Attachment of the given ID is picked up and a
  #   Transfer record is added into the transers table
  #   for accountability. 
  #   At last, the user is redirected to the download URL.
  #FIXME: Make the error reporting more elegant.
  def download
    
    
    begin
      attachment = DetailValue.find params[:id]
      file_path = attachment.local_instance_path + "/#{attachment.id.to_s}"
      file_props = attachment.value
      send_file_spec = attachment.send_file_spec

      case send_file_spec[:method]
        when :redirect
          redirect_to send_file_spec[:data][:url]
	when :send_file
          send_file file_path, :filename => file_props[:filename], 
          		 :type => file_props[:filetype]
      end 
	  
    rescue Exception => e
      render :text => e.message, :status => 500
    end

  end
  
#  # This function will not be in the opensource bracnh
#  def download_s3
#    detail_value_id = params["id"]
#    attachment = S3Attachment.find params["id"]
#    instance = attachment.instance
#    entity = instance.entity
#    account = session["user"].account
#    user = session["user"]
#    file_size = attachment.size
#    #d = Transfer.new( :detail_value_id => attachment.id , :instance => instance, :entity => entity, :account => account, :user => user, :size => file_size, :file => attachment.value[:filename], :direction => 'to_client' )
#    #d.save
#    redirect_to :url => S3Attachment.find(params["id"]).download_url
#  end
end
