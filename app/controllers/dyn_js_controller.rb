class DynJsController < ApplicationController
  def madb_yui
       response.content_type = Mime::JS
       render :layout => false 
  end

end
