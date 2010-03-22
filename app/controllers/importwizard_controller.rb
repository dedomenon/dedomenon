require 'csv'
require 'fastercsv'
require 'tempfile'
class ImportwizardController < ApplicationController
  before_filter :login_required

  #sets t@entity
  before_filter :check_all_ids 

  #step 1
  def index
    @entity = Entity.find params[:id]
  end
  
  #step 2
  def link_fields
    redirect_to :action => "index", :id => params[:id]  and return if params["file_to_import"].blank?
    if params[:separator].blank?
      separator = ","
    else
      separator = params[:separator]
    end
    #save file in user's tmp zone
    f=Tempfile.new(%{#{@entity.name}}, import_temp_dir ) 
    f.print(params["file_to_import"].read) 
    f.close
    csv = nil
    begin
      #csv = FasterCSV::open(f.path, "r", separator)
      csv=FasterCSV.open f.path, :col_sep => separator, :headers => true, :return_headers => true
      # validate file
      FasterCSV.foreach(f.path, :col_sep => separator, :headers => true, :return_headers => true) {} 
      @csv_fields = csv.shift.headers
    rescue FasterCSV::MalformedCSVError => e
      flash["error"]=I18n.t('import_wizard.csv_format_invalid')
      redirect_to :action => "index", :id => params[:id]  and return
    end
    @csv_fields.insert(0, "----")
    @entity_fields = @entity.details_hash.keys
    FileUtils.cp(f.path, f.path+".perm")
    session[:file_to_import]=f.path+".perm"
  end

  def import_data
    @entity = Entity.find params[:id]
    @imported_instances=[]
    @invalid_entries=[]
    @empty_entries = 0
    #default separator is ,
    if params[:separator].blank?
      separator = ","
    else
      separator = params[:separator]
    end
    csv=FasterCSV.open session[:file_to_import], :col_sep => separator , :headers => true, :return_headers => true
    @csv_fields = csv.shift.headers
    @bindings=params[:bindings].inject({}){|acc,i| 
      acc.merge!({ i[0] => @csv_fields.index(i[1]) }) if i[1]!='----' 
      acc
    }

    csv.each do |row| 
    #csv.each do |row| 
      # b[0] is detail
      # b[1] is csv column number
      h = @bindings.inject({}) do |acc,b| 
        acc.merge({b[0] => row[b[1]]}) 
      end
        begin
          i, invalid_fields = Entity.instanciate(params[:id], h)
        rescue Exception => e
          if e.message == "no detail saved"
            @empty_entries+=1
            next
            #ignore, it is an empty row we should not save, but not block on it either
          end
        end
      if i
        @imported_instances.push i.id
      else
        @invalid_entries.push row.to_a.collect{|e| e[1]}
      end
      session[:imported_instances]= @imported_instances unless ActionController::Base.session_store==ActionController::Session::CookieStore
    end

  end

  def delete_imported
      @deleted_items = Instance.destroy_all( :id => session[:imported_instances])
      session[:imported_instances]=nil
  end

  private 
  def check_all_ids
    redirect_to :controller => "database" and return false if  params[:id].nil?
    @entity=Entity.find params[:id]
    if @entity.nil? or !user_dbs.include? @entity.database
      flash["error"] = t("madb_entity_not_in_your_dbs")
      redirect_to :controller => "database" and return false
    end
  end

  def import_temp_dir
    dir = "#{RAILS_ROOT}/tmp/#{session["user"].id}/import/#{@entity.id}"
    FileUtils.mkdir_p dir unless File.exists? dir
    return dir
  end
end
