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

require 'user'

# *Description*
#   This class controls the user authentication services. Logging in, logging out
#   and singhinup are the services provided by this controller
#   
# REST API Services
#   You can log in
#   You can log out
#   You can signup
#   You can change password
#   You can verify an account
#   You can reset the password
#   
#
class AuthenticationController < ApplicationController
  require 'captcha'
  #model   :user
  layout  :determine_layout

  before_filter :login_required, :only => [:change_password]
  filter_parameter_logging :password

  def determine_layout
    if params["action"]=="account_type_explanations"
      return nil
    end
    if params["action"]=="change_password"
      if  !embedded?
        return "application"
      else
        return nil
      end
    else
      return "scaffold"
    end
  end

  # *Description*
  #   Allows the user to log in
  #   
  #   REST API Expectations:
  #     POST:
  #       user:
  #           login
  #           password
  #
  def login
    case request.method
    when :post
      @user = User.new(params['user'])
      
      session['user'] = User.authenticate(params['user']['login'], params['user']['password'])
      #if session['user'] = User.authenticate(params['user']['login'], params['user']['password'])
      if session['user']
        if session["user"].account.allows_login?
          flash['notice'] = "madb_login_successful"
          @user = nil
          redirect_back_or_default :controller => 'database' and return
        else
          if session["user"].account.expired?
            redirect_to :controller => 'payments', :action => "reactivate" and return
          else
            @message = t("madb_account_not_active_or_cancelled")
            SystemNotifier.deliver_authentication_refused(self, request, params["user"]["login"] )
          end
        end

      else
        @login = params['user']['login']
        if user = User.find_by_login(@login);
            if user.verified?
              @message = t("madb_login_unsuccessful")
            else
              if user.account.account_type_id==1
                @message = t("madb_login_unsuccessful_account_not_yet_verified")
              else
                session["user"]=user
                redirect_to :controller => "payments", :action => "complete"

              end
            end
        else
            @message = t("madb_login_unsuccessful")
        end
      end
    when :get
      @user = User.new
    end
  end

  # *Description*
  #   Provides the user with the facility to signup.
  #   
  # *Workflow*
  #   If the request method is get, then we are heading towards presenting
  #   the user a form to fill in the details but if the method is POST then 
  #   the form is populated alreadya we need to create an account and a primary 
  #   user for the account.
  #   If the TOS are accepted and the user is saved, then we see if the account 
  #   was free. If so, we activate it and send a notification mail otherwise
  #   we would redirect the user towards the payments controller.
  #   
  #
  def signup
    @account_types = AccountType.find(:all, :conditions =>[ "active = ?", true]).collect{|t| [t(t.name), t.id ]}
    case request.method
      # if the method is post, we need to create a primary user and an account
    when :post
      @user = User.new(params['user'])
      @user.user_type_id=1
      @account = Account.new(params['account'])
      @account_type_id = params["account_type_id"]
      @account_type_id ||= 1

      @account_type = AccountType.find(@account_type_id)
      @account.account_type = @account_type
      begin
        @user.transaction do
          @user.account = @account
          if params["tos_accepted"]!="on"
            @error_tos=true
          end
          if params["tos_accepted"]=="on" and @user.save
            #@user = nil
            # if its a free account, immediatly activate it and notify through
            # email. Otherwise redirecto to the payments section.
            if @account_type.free?
              @account.status = "active"
              Notify.deliver_signup(@user, params['user']['password'], url_for(:controller=> "authentication", :action => "verify"), { :lang => user_lang})
              flash['notice'] = "Signup successful! Please check your registered email account to verify your account registration and continue with the login."
              redirect_to :action => 'login'
            else
              session["user"]=@user
              redirect_to :controller => 'payments', :action => 'complete'
            end
          end
        end
      rescue Exception => e
        #flash['message'] = "Error creating account: confirmation email not sent. Error was #{e}"
        flash['message'] = t("madb_an_error_prevented_the_creation_of_your_account")
        raise
      end
    when :get
      @user = User.new
      @account = Account.new
    end
  end

  # *Description*
  #   This method returns detailed explanations of the account types.
  #   
  # *Workflow*
  #   This action is used in conjunction with the prototype AJAX classes and
  #   is primarlly used in the signup form where the select box has an AJAX 
  #   Updater at its onChange event. On change, this action is hit and account
  #   Type changes are fetched.
  #
  def account_type_explanations
    @account_type = AccountType.find params["id"]
  end

  # *Description*
  #   Simply logs out the user
  def logout
    session['user'] = nil
    session['return-to'] = nil
    redirect_to :action => 'login'
  end

  # *Description*
  #   Changes the password.
  # FIXME: Tests for this method simply fail because the user object is
  # being stored in session which gets stale by time.
  # This issue came out after the implemenation of optimistic concurrency
  # for the user
  def change_password
    case request.method
    when :post
      @user = session['user']
      @user.attributes = params['user']
      begin
        @user.transaction do
          if @user.save
            @user.change_password(params['user']['password'])
            flash['notice'] = t("madb_notice_password_updated")
            @user = nil
            redirect_back_or_default :action => 'welcome'
          end
          
        end
      rescue Exception => e
        RAILS_DEFAULT_LOGGER.error "Error changing password for user #{@user.login}"
        RAILS_DEFAULT_LOGGER.error e.message
        RAILS_DEFAULT_LOGGER.error e.backtrace[0]
        flash['message'] = "Your password could not be changed at this time. Please retry."
      end
    when :get
      @user = User.new
    end
  end

  # *Description*
  #   Changes the password to a randomly generated password and sends a 
  #   notification email.
  #
  def forgot_password
    case request.method
    when :post
      if params['user']['email'].empty?
        flash['message'] = "please_enter_a_valid_email_address"
      else
        @user = User.find_by_email(params['user']['email'])
        if @user.nil?
          flash['message'] = t("madb_could_not_find_account_with_email", :vars => {'mail' => params['user']['email']})
        else
          @user.password_confirmation = @user.password
          pass = @user.makepass
          begin
            @user.transaction do
#              raise "1: #{@user.password_confirmation} 2: #{@user.password}" # = nil
              if @user.save
                @user.change_password(pass)
                Notify.deliver_forgot_password(@user, pass, url_for(:controller => "authentication", :action=> "login"), {:lang => user_lang} )
                flash['notice'] = t("madb_new_password_sent", :vars => {'mail' =>params['user']['email']})
                @user = nil
                redirect_to :action => 'login' and return  unless !session['user'].nil?
                redirect_back_or_default :action => 'welcome' and return
              end
            end
          rescue Exception => e
            flash['notice'] = t("madb_new_password_could_not_be_mailed", :vars => {'email' => params['user']['email']})
#            raise
          end
        end
      end
    when :get
      @user = User.new
    end
  end

  # *Description*
  #   Sets the user verification field to 1 or true.
  #
  def verify
    user = User.find_by_uuid(params['id'])
    begin
      user.verify
      flash['notice'] = t("madb_account_verified")
    rescue NoMethodError
      flash['message'] = t("madb_account_activation_impossible_because_not_found")
    end
    redirect_to :action => 'login'
  end

  # *Description*
  #   Simply redirects the user to the databases page.
  #
  def welcome
    redirect_to :controller => "database", :action => "index"
  end

  
  def check_captcha
    if CAPTCHA::Web.is_valid( params["key"], params["digest"] )
      demo_users_count = User.count(:conditions => "email like 'demo%@madb.net'")
      session['user'] = User.find( :first , :conditions => "login like 'demo%@madb.net'",:limit => 1, :offset => rand(demo_users_count))
      redirect_to :controller => "database"
    else
      redirect_to :action => "login"
    end
  end

  def demo_login
    @captcha = CAPTCHA::Web.from_configuration( "#{RAILS_ROOT}/vendor/plugins/captcha/captcha.conf" )

  end

  private

  def create_demo_database
      account = Account.new(:name => "demo account", :country => "Belgium")
      password = String.random(8)
      email="demo#{String.random(8)}@madb.net"
      jon = User.new(:login => email,:login_confirmation=> email, :email =>email, :password => password , :password_confirmation => password, :firstname => "jon")
      jon.user_type_id=1
      jon.verified = 1
      jon.account = account

      account.save
      jon.save
      session["user"]=jon

      cd_collection = Database.new(:name=>"CD collection")
      cd_collection.account = account
      cd_collection.save

      entities = {}
      [ "CDs", "artists", "tracks"].each do |n|
        Entity.new(:name => n ) do |e|
          e.database = cd_collection
          e.save
          entities[n]=e
        end
      end

      #########
      #details
      #########
      text_type = DataType.find_by_name "short_text"
      long_text_type = DataType.find_by_name "long_text"
      date_type = DataType.find_by_name "date"
      integer_type = DataType.find_by_name "integer"
      ddl_type = DataType.find_by_name "choose_in_list"
      email_type = DataType.find_by_name "email"

      #create details
      #--------------
      title_detail = Detail.new :name => "title", :data_type => text_type, :status_id => 1, :database => cd_collection
      title_detail.save
      length_detail = Detail.new :name => "length", :data_type => text_type, :status_id => 1, :database => cd_collection
      length_detail.save
      name_detail = Detail.new :name => "name", :data_type => text_type, :status_id => 1, :database => cd_collection
      name_detail.save

      date_detail = Detail.new :name => "year", :data_type => date_type, :status_id => 1, :database => cd_collection
      date_detail.save

      birthday_detail = Detail.new :name => "birthday", :data_type => date_type, :status_id => 1, :database => cd_collection
      birthday_detail.save

      notes_detail = Detail.new :name => "notes", :data_type => long_text_type, :status_id =>1, :database => cd_collection
      notes_detail.save
      #position_detail = Detail.new :name => "position", :data_type => integer_type, :status_id =>1, :database => cd_collection
      #position_detail.save


      number_of_disks=Detail.new :name =>"number_of_disks", :data_type => ddl_type, :status_id => 1, :database => cd_collection
      number_of_disks.save
      one = DetailValueProposition.new :value => "1", :detail => number_of_disks
      one.save
      two = DetailValueProposition.new :value => "2", :detail => number_of_disks
      two.save
      three = DetailValueProposition.new :value => "3", :detail => number_of_disks
      three.save
      four = DetailValueProposition.new :value => "4", :detail => number_of_disks
      four.save
      five = DetailValueProposition.new :value => "5", :detail => number_of_disks
      five.save
      six = DetailValueProposition.new :value => "6", :detail => number_of_disks
      six.save

      ##############
      #link_details#
      ##############
      #CD details
      #----------
      cd_title = EntityDetail.new({"displayed_in_list_view"=> true, "maximum_number_of_values"=> 1, "display_order" => 10, "status_id" => 1, :detail => title_detail, :entity => entities["CDs"], :status_id => 1 })
      cd_title.save

      cd_date = EntityDetail.new({"displayed_in_list_view"=> true, "maximum_number_of_values"=> 1, "display_order" => 20, "status_id" => 1, :detail => date_detail, :entity => entities["CDs"], :status_id => 1 })
      cd_date.save

      cd_number_of_disks = EntityDetail.new({"displayed_in_list_view"=> true, "maximum_number_of_values"=> 1, "display_order" => 30, "status_id" => 1, :detail => number_of_disks, :entity => entities["CDs"], :status_id => 1 })
      cd_number_of_disks.save

      cd_notes = EntityDetail.new({"displayed_in_list_view"=> false, "maximum_number_of_values"=> 1, "display_order" => 50, "status_id" => 1, :detail => notes_detail, :entity => entities["CDs"], :status_id => 1 })
      cd_notes.save
      #
      #artists details
      #----------
      artist_name = EntityDetail.new({"displayed_in_list_view"=> true, "maximum_number_of_values"=> 1, "display_order" => 10, "status_id" => 1, :detail => name_detail, :entity => entities["artists"], :status_id => 1 })
      artist_name.save
      artist_notes = EntityDetail.new({"displayed_in_list_view"=> false, "maximum_number_of_values"=> 1, "display_order" => 50, "status_id" => 1, :detail => notes_detail, :entity => entities["artists"], :status_id => 1 })
      artist_notes.save
      artist_birthday = EntityDetail.new({"displayed_in_list_view"=> true, "maximum_number_of_values"=> 1, "display_order" => 20, "status_id" => 1, :detail => birthday_detail, :entity => entities["artists"], :status_id => 1 })
      artist_birthday.save

      #tracks
      #------
      #tracks_position = EntityDetail.new({"displayed_in_list_view"=> true, "maximum_number_of_values"=> 1, "display_order" => 0, "status_id" => 1, :detail => position_detail, :entity => entities["tracks"], :status_id => 1 })
      #tracks_position.save
      tracks_title = EntityDetail.new({"displayed_in_list_view"=> true, "maximum_number_of_values"=> 1, "display_order" => 10, "status_id" => 1, :detail => title_detail, :entity => entities["tracks"], :status_id => 1 })
      tracks_title.save
      tracks_length = EntityDetail.new({"displayed_in_list_view"=> true, "maximum_number_of_values"=> 1, "display_order" => 20, "status_id" => 1, :detail => length_detail, :entity => entities["tracks"], :status_id => 1 })
      tracks_length.save

      #relation types
      one_side= RelationSideType.find_by_name "one"
      many= RelationSideType.find_by_name "many"
      #
      #link CD with artist
      cd_author_relation = Relation.new :parent => entities["artists"], :child => entities["CDs"], :parent_side_type => many, :child_side_type => many, :from_parent_to_child_name => "singer on", :from_child_to_parent_name => "sung by"
      cd_author_relation.save
      #link CD with with track
      cd_track_relation = Relation.new :parent => entities["CDs"], :child => entities["tracks"], :parent_side_type => one_side, :child_side_type => many, :from_parent_to_child_name => "contains", :from_child_to_parent_name => "is on"
      cd_track_relation.save


      cd_instances={}

      [
        { :title => "Boris", :date => "1996-05-01", :disks => one, :notes =>"This is a psychedelic CD narrating the story of Boris, with different adventures he lives, likes the travel in space or in a black box"},
        { :title => "Ray of light", :date => "1997-05-01", :disks => one},
        { :title => "23 siempre", :date => "2003-10-01", :disks => one, :notes =>"First CD of the winner of Pop Idol in France."},
        { :title => "The presidents of USA", :date => "1995-10-01", :disks => one, :notes =>"Really good man. Hilarous lyrics!"},
        { :title => "The presidents of USA II", :date => "1998-10-01", :disks => one, :notes =>"As good as their first CD!"},
        { :title => "Black or white", :date => "1992-05-01", :disks => one},
        { :title => "Patience", :date => "2004-01-01", :disks => one, :notes=>"http://www.google.be/"},
        { :title => "Kylie", :date => "1988-01-01", :disks => one, :notes=>"http://www.freedb.org/freedb_search_fmt.php?cat=misc&id=8a084c0a²"},
        { :title => "Songs in a minor", :disks => one, :notes=>"http://www.freedb.org/freedb_search_fmt.php?cat=rock&id=e40ff311"},
        { :title => "Simply the truth", :disks => one, :notes=>"http://www.freedb.org/freedb_search_fmt.php?cat=blues&id=e710b510"},
        { :title => "Forever gold", :disks => one, :notes=>"http://www.freedb.org/freedb_search_fmt.php?cat=jazz&id=d50b7510"},
        { :title => "bon jovi", :disks => one, :notes=>"http://www.freedb.org/freedb_search_fmt.php?cat=rock&id=5308f909"},
        { :title => "Purple rain", :disks => one, :notes=>"http://www.freedb.org/freedb_search_fmt.php?cat=misc&id=740a4809"},
        { :title => "Marcher dans le sable", :disks => one, :notes=>"http://www.freedb.org/freedb_search_fmt.php?cat=rock&id=a809e90c"},
        { :title => "Non homologué", :disks => one, :notes=>"http://www.freedb.org/freedb_search_fmt.php?cat=misc&id=a30b680b"},
        { :title => "Double jeu", :disks => one, :notes=>"http://www.freedb.org/freedb_search_fmt.php?cat=misc&id=6a0b6d0a"},
        { :title => "A contre jour", :disks => one, :notes=>"http://www.freedb.org/freedb_search_fmt.php?cat=blues&id=9b0a7f0b"},
        { :title => "One million dollars hotel", :disks => one, :notes=>"<a href=\"http://www.freedb.org/freedb_search_fmt.php?cat=classical&id=da0d0e10\">test</A>"},
        { :title => "music", :disks => one},
        { :title => "something to remember", :disks => one},
        { :title => "bedtime stories", :disks => one},
      ]. each do |cd|
        cd_instance = Instance.new :entity => entities["CDs"]
        cd_instance.save
        cd_instances[cd[:title].downcase]=cd_instance

        cd_instance_title = DetailValue.new :detail => cd_title.detail, :instance => cd_instance, :value => cd[:title]
        cd_instance_title.save
        cd_instance_year =  DateDetailValue.new :detail => cd_date.detail , :instance => cd_instance, :value => cd[:date]
        cd_instance_year.save
        cd_instance_disks = DdlDetailValue.new :detail => cd_number_of_disks.detail , :instance => cd_instance, :detail_value_proposition => cd[:disks]
        cd_instance_disks.save
        cd_instance_notes = LongTextDetailValue.new :detail => cd_notes.detail, :instance => cd_instance, :value => cd[:notes]
        cd_instance_notes.save
      end

      artist_instances = {}
      [
        { :name => "Madonna" },
        { :name => "The presidents of USA" },
        { :name => "Gérald de Palma" },
        { :name => "François Feldman" },
        { :name => "U2" },
        { :name => "Boris" },
        { :name => "Jean-Jacques Goldman" },
        { :name => "Alicia Keys" },
        { :name => "Prince" },
        { :name => "Michael Jackson" },
        { :name => "Georges Michael" },
        { :name => "Michel Berger" },
        { :name => "France Gall" },
        { :name => "Clouseau" },
        { :name => "Axelle Red" },
        { :name => "Kate Bush" },
        { :name => "Blur" },
        { :name => "Oasis" },
        { :name => "Robbie Willians" },
        { :name => "Basement Jaxx" },
        { :name => "John Lennon" },
        { :name => "Paul McCartney" },
        { :name => "The Beatles" },
        { :name => "Sheila" },
        { :name => "Demis Roussos" },
        { :name => "Stevie Wonder" },
        { :name => "Elvis Presley" },
        { :name => "John Lee Hooker" },
        { :name => "Eurythmics" },
        { :name => "Vaya con dios" },
        { :name => "Ricky Martin" },
        { :name => "Georges Brassens" },
        { :name => "Georges Moustaki" },
        { :name => "Maria Calas" },
        { :name => "Annie Cordi" },
        { :name => "Nana Mouskouri" },
        { :name => "Les gauf au suc" },
        { :name => "The cardigans" },
        { :name => "The Corrs" },
        { :name => "Sttellla" },
        { :name => "Genesis" },
        { :name => "Alanis Morissette" },
        { :name => "Peter Gabriel" },
        { :name => "Johnny Halliday" },
        { :name => "Beach Boys" },
        { :name => "Bee gees" },
        { :name => "Frank Sinatra" },
        { :name => "Pow wow" },
        { :name => "Anouk" },
        { :name => "Wham" },
        { :name => "Europe" },
        { :name => "Garbage" },
        { :name => "Guns & Roses" },
        { :name => "TLC" },
        { :name => "Julio Iglesias" },
        { :name => "Toto Cotunio" },
        { :name => "Johnny Logan" },
        { :name => "Pixies" },
        { :name => "The Ramones" },
        { :name => "Iron Maiden" },
        { :name => "Black Sabbath" },
        { :name => "Metallica" },
        { :name => "Nirvana" },
        { :name => "Kylie Minogue" },
        { :name => "Raphael" },
        { :name => "Indochine" },
        { :name => "Elton John" },
        { :name => "Jenifer Lopez" },
        { :name => "Eagle Eye Cherry" },
        { :name => "Justin Timberlake" },
        { :name => "N'sync" },
        { :name => "Back stree boys" },
        { :name => "Simply red" },
        { :name => "Simple minds" },
        { :name => "The cure" },
        { :name => "Toto" },
        { :name => "Black eye peas" },
        { :name => "Pink" },
        { :name => "Bony Tyler" },
        { :name => "Eros Ramazotti" },
        { :name => "Claude Barzotti" },
        { :name => "Adamo" },
        { :name => "Lio" },
        { :name => "Plastic Bertranc" },
        { :name => "Apollo 440" },
        { :name => "UB40" },
        { :name => "Front 242" },
        { :name => "Claude François" },
        { :name => "No doubt" },
        { :name => "Texas" },
        { :name => "Aha" },
        { :name => "Boy George" },
        { :name => "Culture club" },
        { :name => "ZZ Top" },
        { :name => "Ronan Keating" },
        { :name => "Richard Gotainer" },
        { :name => "Alain Chamfort" },
        { :name => "Jamiroquai" },
        { :name => "Serge Lama" },
        { :name => "Francis Cabrel" },
        { :name => "Ella Fitzerald" },
      ].each  do |a|
        artist_instance = Instance.new :entity => entities["artists"]
        artist_instance.save
        artist_instances[a[:name].downcase]=artist_instance
        artist_instance_name = DetailValue.new :detail => artist_name.detail, :instance => artist_instance, :value => a[:name]
        artist_instance_name.save

      end


      [
        [ "madonna", "ray of light"],
        [ "madonna", "music"],
        [ "madonna", "bedtime stories"],
        [ "madonna", "something to remember"],
        [ "the presidents of usa", "the presidents of usa"],
        [ "the presidents of usa", "the presidents of usa ii"],
        [ "boris", "boris"],
        [ "michael jackson", "black or white"],
        [ "georges michael", "patience"],
        [ "kylie minogue", "kylie"],
        [ "bon jovi", "bon jovi"],
        [ "john lee hooker", "simply the truth"],
        [ "ella fitzerald", "forever gold"],
        [ "prince", "purple rain"],
        [ "gérald de palma","marcher dans le sable"],
        [ "jean-jacques goldman","non homologué"],
        [ "michel berger","double jeu"],
        [ "france gall","double jeu"],
        [ "françois feldman","a contre jour"],
        [ "alicia keys","songs in a minor"],
      ]. each do |l|
        link = Link.new :relation => cd_author_relation, :parent => artist_instances[l[0]], :child => cd_instances[l[1]]
        link.save
      end

      albums_dir = %Q(#{RAILS_ROOT}/lib/albums)
      Dir.foreach(albums_dir) do |f|
        title = f.sub(".csv","").gsub("_"," ")
        next if [".",".."].include? f
        CSV.open(albums_dir+"/"+f,"r") do |row|
          next if row.length<3
          track_instance= Instance.new :entity => entities["tracks"]
          track_instance.save
          track_instance_title = DetailValue.new :detail => tracks_title.detail, :instance => track_instance, :value => row[2]
          track_instance_title.save
          track_instance_length = DetailValue.new :detail => tracks_length.detail, :instance => track_instance, :value => row[1]
          track_instance_length.save
          track_instance_position = DetailValue.new :detail => tracks_length.detail, :instance => track_instance, :value => row[1]
          track_instance_length.save
          #track_instance_position = DetailValue.new :detail => tracks_position.detail, :instance => track_instance, :value => row[0]
          #track_instance_position.save

          link= Link.new :relation => cd_track_relation, :parent => cd_instances[title], :child => track_instance
          link.save
        end

      end


      #########################################
      # customers database
      #########################################

      customers_database = Database.new(:name=>"Customers")
      customers_database.account = account
      customers_database.save

      #create entities
      #---------------
      entities = {}
      [ "companies", "contacts", "invoices", "communications"].each do |n|
        Entity.new(:name => n ) do |e|
          e.database = customers_database
          e.save
          entities[n]=e
        end
      end

      #create details
      #--------------
      name_detail = Detail.new :name => "name", :data_type => text_type, :status_id => 1, :database => customers_database
      name_detail.save

      address_detail = Detail.new :name => "address", :data_type => text_type, :status_id => 1, :database => customers_database
      address_detail.save
      city_detail = Detail.new :name => "city", :data_type => text_type, :status_id => 1, :database => customers_database
      city_detail.save
      phone_detail = Detail.new :name => "phone", :data_type => text_type, :status_id => 1, :database => customers_database
      phone_detail.save
      fax_detail = Detail.new :name => "fax", :data_type => text_type, :status_id => 1, :database => customers_database
      fax_detail.save
      website_detail = Detail.new :name => "website", :data_type => text_type, :status_id => 1, :database => customers_database
      website_detail.save
      email_detail = Detail.new :name => "email", :data_type => email_type , :status_id => 1, :database => customers_database
      email_detail.save
      vat_detail = Detail.new :name => "vat", :data_type => text_type, :status_id => 1, :database => customers_database
      vat_detail.save


      first_name_detail = Detail.new :name => "first_name", :data_type => text_type, :status_id => 1, :database => customers_database
      first_name_detail.save
      surnamedetail = Detail.new :name => "surname", :data_type => text_type, :status_id => 1, :database => customers_database
      surnamedetail.save

      number_detail  = Detail.new :name => "invoice_number", :data_type => text_type, :status_id => 1, :database => customers_database
      number_detail.save
      date_detail  = Detail.new :name => "date", :data_type => date_type, :status_id => 1, :database => customers_database
      date_detail.save
      sent_on_detail  = Detail.new :name => "invoice_sent_on", :data_type => date_type, :status_id => 1, :database => customers_database
      sent_on_detail.save
      paid_on_detail  = Detail.new :name => "invoice_paid_on", :data_type => date_type, :status_id => 1, :database => customers_database
      paid_on_detail.save


      notes_detail  = Detail.new :name => "notes", :data_type => long_text_type, :status_id => 1, :database => customers_database
      notes_detail.save
      subject_detail  = Detail.new :name => "subject", :data_type => text_type, :status_id => 1, :database => customers_database
      subject_detail.save

      #link details
      #------------


      company_name = EntityDetail.new({"displayed_in_list_view"=> true, "maximum_number_of_values"=> 1, "display_order" => 0, "status_id" => 1, :detail => name_detail, :entity => entities["companies"], :status_id => 1 })
      company_name.save
      company_address = EntityDetail.new({"displayed_in_list_view"=> false, "maximum_number_of_values"=> 1, "display_order" => 10, "status_id" => 1, :detail => address_detail, :entity => entities["companies"], :status_id => 1 })
      company_address.save
      company_city = EntityDetail.new({"displayed_in_list_view"=> false, "maximum_number_of_values"=> 1, "display_order" => 20, "status_id" => 1, :detail => city_detail, :entity => entities["companies"], :status_id => 1 })
      company_city.save
      company_vat = EntityDetail.new({"displayed_in_list_view"=> false, "maximum_number_of_values"=> 1, "display_order" => 30, "status_id" => 1, :detail => vat_detail, :entity => entities["companies"], :status_id => 1 })
      company_vat.save
      company_phone = EntityDetail.new({"displayed_in_list_view"=> false, "maximum_number_of_values"=> 1, "display_order" => 40, "status_id" => 1, :detail => phone_detail, :entity => entities["companies"], :status_id => 1 })
      company_phone.save
      company_fax = EntityDetail.new({"displayed_in_list_view"=> false, "maximum_number_of_values"=> 1, "display_order" => 50, "status_id" => 1, :detail => fax_detail, :entity => entities["companies"], :status_id => 1 })
      company_fax.save
      company_website = EntityDetail.new({"displayed_in_list_view"=> true, "maximum_number_of_values"=> 1, "display_order" => 60, "status_id" => 1, :detail => website_detail, :entity => entities["companies"], :status_id => 1 })
      company_website.save
      company_email = EntityDetail.new({"displayed_in_list_view"=> true, "maximum_number_of_values"=> 1, "display_order" => 70, "status_id" => 1, :detail => email_detail, :entity => entities["companies"], :status_id => 1 })
      company_email.save
      #
      #------------------
      #
      contact_surname = EntityDetail.new({"displayed_in_list_view"=> true, "maximum_number_of_values"=> 1, "display_order" => 0, "status_id" => 1, :detail => surnamedetail, :entity => entities["contacts"], :status_id => 1 })
      contact_surname.save
      contact_first_name = EntityDetail.new({"displayed_in_list_view"=> true, "maximum_number_of_values"=> 1, "display_order" => 10, "status_id" => 1, :detail => first_name_detail, :entity => entities["contacts"], :status_id => 1 })
      contact_first_name.save
      contact_email = EntityDetail.new({"displayed_in_list_view"=> true, "maximum_number_of_values"=> 1, "display_order" => 20, "status_id" => 1, :detail => email_detail, :entity => entities["contacts"], :status_id => 1 })
      contact_email.save
      contact_phone = EntityDetail.new({"displayed_in_list_view"=> true, "maximum_number_of_values"=> 1, "display_order" => 30, "status_id" => 1, :detail => phone_detail, :entity => entities["contacts"], :status_id => 1 })
      contact_phone.save
      #
      #-------------------------
      #
      invoice_number = EntityDetail.new({"displayed_in_list_view"=> true, "maximum_number_of_values"=> 1, "display_order" => 0, "status_id" => 1, :detail => number_detail, :entity => entities["invoices"], :status_id => 1 })
      invoice_number.save
      invoice_date = EntityDetail.new({"displayed_in_list_view"=> true, "maximum_number_of_values"=> 1, "display_order" => 10, "status_id" => 1, :detail => date_detail, :entity => entities["invoices"], :status_id => 1 })
      invoice_date.save
      invoice_sent_on = EntityDetail.new({"displayed_in_list_view"=> false, "maximum_number_of_values"=> 1, "display_order" => 20, "status_id" => 1, :detail => sent_on_detail, :entity => entities["invoices"], :status_id => 1 })
      invoice_sent_on.save
      invoice_paid_on = EntityDetail.new({"displayed_in_list_view"=> false, "maximum_number_of_values"=> 1, "display_order" => 30, "status_id" => 1, :detail => paid_on_detail, :entity => entities["invoices"], :status_id => 1 })
      invoice_paid_on.save

      #
      #------------------
      #
      communications_date = EntityDetail.new({"displayed_in_list_view"=> true, "maximum_number_of_values"=> 1, "display_order" => 20, "status_id" => 1, :detail => date_detail, :entity => entities["communications"], :status_id => 1 })
      communications_date.save
      communications_subject = EntityDetail.new({"displayed_in_list_view"=> true, "maximum_number_of_values"=> 1, "display_order" => 20, "status_id" => 1, :detail => subject_detail, :entity => entities["communications"], :status_id => 1 })
      communications_subject.save
      communications_notes = EntityDetail.new({"displayed_in_list_view"=> false, "maximum_number_of_values"=> 1, "display_order" => 20, "status_id" => 1, :detail => notes_detail, :entity => entities["communications"], :status_id => 1 })
      communications_notes.save


      ##############
      #link entities
      ##############

      company_contact_relation = Relation.new :parent => entities["companies"], :child => entities["contacts"], :parent_side_type => many, :child_side_type => many, :from_parent_to_child_name => "has contact", :from_child_to_parent_name => "is contact for"
      company_contact_relation.save
      company_invoice_relation = Relation.new :parent => entities["companies"], :child => entities["invoices"], :parent_side_type => one_side, :child_side_type => many, :from_parent_to_child_name => "invoices list", :from_child_to_parent_name => "customer invoiced"
      communications_contacts_relation = Relation.new :parent => entities["communications"], :child => entities["contacts"], :parent_side_type => many, :child_side_type => many, :from_parent_to_child_name => "person contacted", :from_child_to_parent_name => "involved in"
      communications_contacts_relation.save
      communications_company_relation = Relation.new :parent => entities["communications"], :child => entities["companies"], :parent_side_type => many, :child_side_type => one_side, :from_parent_to_child_name => "communication with", :from_child_to_parent_name => "communications"
      communications_company_relation.save

 companies = ["Alcides","Alcmena","Alcmene","Alcyone","Alecto","Alectrona","Alexandra","Aloadae","Alpheos","Alpheus","Amarynthia","Ampelius","Amphion","Amphitrite","Amphitryon","Amymone","Ananke","Andromeda","Antaeus","Antaios","Anteros","Anticlea","Antiklia","Antiope","Apate","Aphrodite","Apollo","Apollon","Aquilo","Arachne","Arcas","Ares","Arethusa","Argeos","Argus","Ariadne","Arion","Arion(2)","Aristaeus","Aristaios","Aristeas","Arkas","Artemis","Asclepius","Asklepios","Asopus","Asteria","Asterie","Astraea","Astraeus","Atalanta","Ate","Athamas","Athamus","Athena","Athene","Atlantides","Atlas","Atropos","Attis","Attropus","Augean-stables","Augian-stables","Aurai","Autolycus","Autolykos","Auxesia","Bacchae","Bacchantes","Bellerophon","Bia","Bias","Boreads","Boreas","Briareos","Briareus","Bromios","Cadmus","Caeneus","Caenis","Calais","Calchas","Calliope","Callisto","Calypso","Cassandra","Castor","Cecrops","Celaeno","Celoneo","Ceneus","Cerberus","Cercopes","Cerigo","Cerynean-hind","Ceryneian-hind","Cerynitis","Ceto","Chaos","Charites","Charon","Charybdis","Cheiron","Chelone","Chimaera","Chimera","Chione","Chiron","Chloe","Chloris","Chronos","Chronus","Circe","Clio","Clotho","Clymene","Coeus","Coltus","Comus","Cottus","Cotys","Cotytto","Cretan-bull","Crius","Cronos","Cronus","Cybele","Cyclopes","Cynthia","Cyrene","Cytherea","Danae","Daphnaie","Decima","Deimos","Deimus","Deino","Delos","Delphyne","Demeter","Demphredo","Deo","Despoena","Deucalion","Deukalion","Dice","Dike","Dione","Dionysos","Dionysus","Dioscuri","Dithyrambos","Doris","Dryades","Dryads","Echidna","Echo","Eileithyia","Eirene","Ekhidna","Ekho","Electra","Electra(2)","Electra(3)","Elektra","Eleuthia","Elpis","Empousa","Empousai","Empusa","Enosichthon","Enyalius","Enyo","Eos","Epaphos","Epaphus","Ephialtes","Epimeliades","Epimeliads","Epimelides","Epimetheus","Epiona","Epione","Epiphanes","Erato","Erebos","Erebus","Erichthoneus","Erichthonius","Erinyes","Eris","Eros","Erotes","Erymanthean-boar","Erymanthian-boar","Erytheia","Erytheis","Erythia","Ether","Eumenides","Eunomia","Euphrosyne","Europa","Euros","Eurus","Euryale","Eurybia","Eurydice","Eurynome","Eurystheus","Euterpe","Fates","Furies","Ga","Gaea","Gaia","Gaiea","Galeotes","Ganymede","Ganymedes","Ge","Geryon","Geryones","Geyron","Glaucus","Gorgons","Graces","Graeae","Graiae","Graii","Gratiae","Gyes","Gyges","Hades","Haides","Halcyone","Hamadryades","Hamadryads","Hapakhered","Harmonia","Harmony","Harpies","Harpocrates","Harpyia","Harpyiai","Hebe","Hecate","Hecatoncheires","Hecatonchires","Hekate","Hekatonkheires","Helen","Helice","Helios","Helius","Hemera","Hemere","Hephaestus","Hephaistos","Hera","Heracles","Herakles","Hercules","Hermaphroditos","Hermaphroditus","Hermes","Hespera","Hesperethousa","Hesperia","Hesperides","Hesperids","Hesperie","Hesperos","Hesperus","Hestia","Himeros","Hippolyta","Hippolytos","Hippolytta","Hippolytus","Hope","Horae","Horai","Hyacinthus","Hyades","Hydra","Hydriades","Hydriads","Hygeia","Hygieia","Hymen","Hymenaeus","Hymenaios","Hyperion","Hypnos","Hypnus","Hyppolyta","Hyppolyte","Iacchus","Iambe","Iapetos","Iapetus","Ilithyia","Ilythia","Inachus","Ino","Io","Ion","Iphicles","Irene","Iris","Kadmos","Kalais","Kalliope","Kallisto","Kalypso","Kekrops","Kelaino","Kerberos","Keres","Kerkopes","Keto","Khaos","Kharon","Kharybdis","Kheiron","Khelone","Khimaira","Khione","Khloris","Khronos","Kirke","Kleio","Klotho","Klymene","Koios","Komos","Kore","Kottos","Krios","Kronos","Kronus","Kybele","Kyklopes","Kyrene","Lachesis","Laertes","Lakhesis","Lamia","Lampetia","Lampetie","Leda","Leimoniades","Leimoniads","Lethe","Leto","Limoniades","Limoniads","Linus","Maenads","Maia","Maiandros","Maliades","Mares-of-diomedes","Meandrus","Medea","Medousa","Medusa","Meliades","Meliads","Meliai","Melidae","Melpomene","Memnon","Menoetius","Menoitos","Merope","Metis","Minos","Minotaur","Mnemosyne","Modesty","Moirae","Moirai","Momos","Momus","Mopsus","Mormo","Mormolykeia","Morpheus","Morta","Mousai","Muses","Myiagros","Naiades","Naiads","Naias","Nemean-lion","Nemeian-lion","Nemesis","Nephele","Nereides","Nereids","Nereus","Nike","Nikothoe","Niobe","Nomios","Nona","Notos","Notus","Nox","Nymphai","Nymphs","Nyx","Oannes","Obriareos","Oceanides","Oceanids","Oceanus","Ocypete","Odysseus","Oeager","Oeagrus","Oenomaus","Oinone","Okeanides","Okypete","Okypode","Okythoe","Omphale","Oreades","Oreads","Oreiades","Oreiads","Oreithuia","Oreithyia","Orion","Orithyea","Orithyia","Orpheus","Orphus","Orth","Orthrus","Ossa","Otus","Ourania","Ouranos","Paeon","Paieon","Paion","Pallas","Pallas(2)","Pallas(3)","Pallas(4)","Pallas(5)","Pallas-athena","Pan","Panacea","Panakeia","Pandemos","Pandora","Pasiphae","Pasithea","Pegasos","Pegasus","Pelops","Pemphredo","Penia","Penie","Perse","Perseis","Persephone","Perseus","Persis","Perso","Petesuchos","Phaethousa","Phaethusa","Phaeton","Phantasos","Phema","Pheme","Phemes","Philammon","Philomenus","Philyra","Philyre","Phobetor","Phobos","Phobus","Phoebe","Phoebe(2)","Phoibe","Phorcys","Phorkys","Phospheros","Pleiades","Ploutos","Plutus","Podarge","Podarke","Pollux","Polyhymnia","Polymnia","Polyphemos","Polyphemus","Pontos","Pontus","Poros","Porus","Poseidon","Priapos","Priapus","Prometheus","Proteus","Psyche","Pyrrha","Python","Rhadamanthus","Rhadamanthys","Rhamnusia","Rhea","Rheia","Sabazius","Salmoneus","Sarpedon","Scamander","Scylla","Seilenos","Seirenes","Selene","Semele","Serapis","Sibyl-of-cumae","Sibyls","Silenos","Silenus","Sirens","Sisyphus","Sito","Skamandros","Skylla","Spercheios","Spercheus","Sperkheios","Sphinx(2)","Sterope","Stheno","Stymphalian-birds","Stymphalion-birds","Styx","Syrinx","Tantalus","Tartaros","Tartarus","Taygete","Telchines","Telkhines","Terpsichore","Terpsikhore","Tethys","Thalassa","Thaleia","Thalia","Thamrys","Thanatos","Thanatus","Thanotos","Thaumas","Thea","Thebe","Theia","Thelxinoe","Themis","Theseus","Thetis","Thetys","Three-fates","Titanes","Titanides","Titans","Tithonus","Triptolemos","Triptolemus","Triton","Tritones","Tyche","Tykhe","Typhoeus","Typhon","Ulysses","Urania","Uranus","Zephyros","Zephyrs","Zephyrus","Zetes","Zethes","Zethus","Zeus"]

      cities = [ "Brussels", "Athens","Barcelona", "Lisboa", "Gent", "Leuven", "Louvain-la-Neuve", "Paris", "Florence", "Valence", "London", "Canterbury", "Luxemburg","Vianden", "Aachen", "Liège", "Montpellier", "Cannes", "Bordeaux", "New York", "Miami", "Melbourne", "Sidney", "Thessaloniki", "Chania", "Rome", "Venice", "Pisa", "Charleroi", "Antwerpen", "Boston", "Saint Petersburg", "Toronto", "Mexico", "Capri", "Oslo", "Copenhagen","Helsinki", "Glasgow", "Virton", "Moskow", "Tokyo", "Peking", "Ouagadougou", "Dubai", "Kinshasa"]

  streets = ["ACKLEY LN" ,"AGNESE ST" ,"ALBEMARLE ST" ,"ALDERMAN RD" ,"ALLEN DR" ,"ALLIED LN" ,"ALLIED ST" ,"ALTAMONT CIR" ,"ALTAMONT ST" ,"ALTAVISTA AVE" ,"AMHERST ST" ,"ANDERSON ST" ,"ANTOINETTE AVE" ,"ANTOINETTE CT" ,"APPLE TREE RD" ,"ARBOR CIR" ,"ARLINGTON CT" ,"ASHBY PL" ,"AUGUSTA ST" ,"AZALEA DR" ,"AZALEA ST" ,"BAILEY RD" ,"BAINBRIDGE ST" ,"BAKER ST" ,"BANBURY ST" ,"BARBOUR DR" ,"BARKSDALE ST" ,"BAYLOR LN" ,"BEECHWOOD DR" ,"BELLEVIEW AVE" ,"BELLEVIEW ST" ,"BELMONT AVE" ,"BELMONT PK" ,"BENT CREEK RD" ,"BERRING ST" ,"BIRDWOOD CT" ,"BIRDWOOD RD" ,"BLAND CIR" ,"BLENHEIM AVE" ,"BLUE RIDGE COMMONS" ,"BLUE RIDGE RD" ,"BOLLING AVE" ,"BOLLINGWOOD RD" ,"BOOKER ST" ,"BRANDON AVE" ,"BRANDYWINE CT" ,"BRANDYWINE DR" ,"BRIARCLIFF AVE" ,"BROAD AVE" ,"BROOKWOOD DR" ,"BROWN ST" ,"BRUCE AVE" ,"BRUNSWICK RD" ,"BUCKINGHAM RD" ,"BUNKER HILL DR" ,"BURGESS LN" ,"BURNET ST" ,"BURNLEY AVE" ,"CABELL AVE" ,"CALHOUN ST" ,"CAMBRIDGE CIR" ,"CAMELLIA DR" ,"CAMERON LN" ,"CARGIL LN" ,"CARLTON AVE" ,"CARLTON RD" ,"CAROLINE AVE" ,"CARROLLTON TER" ,"CARTER LN" ,"CASTALIA ST" ,"CEDAR HILL RD" ,"CEDARS CT" ,"CENTER AVE" ,"CHANCELLOR ST" ,"CHARLTON AVE" ,"CHELSEA DR" ,"CHERRY AVE" ,"CHERRY ST" ,"CHESAPEAKE ST" ,"CHESTNUT ST" ,"CHISHOLM PL" ,"CHURCH ST" ,"CLARKE CT" ,"CLEVELAND AVE" ,"CLYDE ST" ,"COCHRAN ST" ,"COLEMAN CT" ,"COLEMAN ST" ,"COMMERCE ST" ,"CONCORD AVE" ,"CONCORD DR" ,"COURT SQ" ,"CREAM ST" ,"CRESAP RD" ,"CRESTMONT AVE" ,"CULBRETH RD" ,"CUTLER LN" ,"CYNTHIANNA AVE" ,"DAIRY RD" ,"DALE AVE" ,"DANBURY CT" ,"DARIEN TERR" ,"DAVID TER" ,"DAVIS AVE" ,"DEL MAR DR" ,"DELL LN" ,"DELEVAN" ,"DELLMEAD LN" ,"DENICE LN" ,"DICE ST" ,"DOUGLAS AVE" ,"DRUID AVE" ,"DUBLIN RD" ,"DUKE ST" ,"DUNOVA CT" ,"DYMOND RD" ,"EARHART ST" ,"EARLY ST" ,"EAST VIEW ST" ,"EDGEHILL RD" ,"EDGEWOOD LN" ,"ELIZABETH AVE" ,"ELKHORN RD" ,"ELLIEWOOD AVE" ,"ELLIOTT AVE" ,"ELM ST" ,"ELSOM ST" ,"S EMMET ST" ,"ERIC PL" ,"ESSEX RD" ,"ESTES ST" ,"ETON RD" ,"EVERGREEN AVE" ,"FAIRWAY AVE" ,"FARISH ST" ,"FARM LN" ,"FAUQUIER RD" ,"FENDALL AVE" ,"FENDALL TER" ,"FERN CT" ,"FIELD RD" ,"FLINT DR" ,"FLORENCE RD" ,"FOREST HILLS AVE" ,"FOREST RIDGE RD" ,"FOREST ST" ,"FOXBROOK LN" ,"FRANKLIN ST" ,"GALLOWAY DR" ,"GARDEN DR" ,"GARDEN ST" ,"GARRETT ST" ,"GENTRY LN" ,"GILDERSLEEVE WOOD" ,"GILLESPIE AVE" ,"GLEASON ST" ,"GLEN AVE" ,"GLENDALE RD" ,"GLENN CT" ,"GOODMAN ST" ,"GORDON AVE" ,"GRACE ST" ,"GRADY AVE" ,"GRAVES ST" ,"GREEN ST" ,"GREENBRIER TER" ,"GREENLEAF LN" ,"GREENWAY RD" ,"GREENWICH CT" ,"GROVE AVE" ,"GROVE RD" ,"GROVE ST" ,"GROVE ST EXT" ,"GROVER CT" ,"HAMMOND ST" ,"HAMPTON ST" ,"HANOVER ST" ,"HARDWOOD AVE" ,"HARDY DR" ,"HARMON ST" ,"HARRIS ST" ,"HARROW RD" ,"HARTFORD CT" ,"HARTMAN'S MILL RD" ,"HAZEL ST" ,"HEDGE ST" ,"HEMLOCK LN" ,"HENRY AVE" ,"HERNDON RD" ,"HESSIAN RD" ,"E HIGH ST" ,"W HIGH ST" ,"HIGHLAND AVE" ,"HILL ST" ,"HILLCREST RD" ,"HILLTOP RD" ,"HILLWOOD PL" ,"HILTON DR" ,"HINTON AVE" ,"HOLIDAY DR" ,"HOLLY CT" ,"HOLLY DR" ,"HOLLY RD" ,"HOLLY ST" ,"HOLMES AVE" ,"HOWARD DR" ,"INDIA RD" ,"JAMESTOWN DR" ,"JEFFERSON PARK AVE" ,"JEFFERSON PARK CIR" ,"KEENE CT" ,"KELLY AVE" ,"KELSEY CT" ,"KENSINGTON AVE" ,"INTERSTATE 64" ,"E JEFFERSON ST" ,"W JEFFERSON ST" ,"JOHN ST" ,"KENT RD" ,"KENT TER" ,"KENWOOD CIR" ,"KENWOOD LN" ,"KERRY LN" ,"JOHNNY CAKE LN" ,"JONES ST" ,"KEYSTONE PL" ,"KING MOUNTAIN RD" ,"KING ST" ,"KNOLL ST" ,"LAFAYETTE ST" ,"LAMBETH LN" ,"LANDONIA CIR" ,"LANE RD" ,"LANKFORD AVE" ,"LAUREL CIR" ,"LEAKE LN" ,"LEHIGH CIR" ,"LEIGH PL" ,"LEONARD ST" ,"LESTER DR" ,"LEVY AVE" ,"LEWIS MOUNTAIN CIR" ,"LEWIS MOUNTAIN RD" ,"LEWIS ST" ,"LEXINGTON AVE" ,"LILI LN" ,"LINDA CT" ,"LINDEN AVE" ,"LINDEN ST" ,"LINE DR" ,"LITTLE GRAVES ST" ,"LITTLE HIGH ST" ,"LOCUST LN" ,"LOCUST LANE CT" ,"LODGE CREEK CIR" ,"LONG ST" ,"LONGWOOD DR" ,"LOUDON AVE" ,"LOVERS LN" ,"LYMAN ST" ,"LYONS AVE" ,"LYONS CT" ,"LYONS COURT LN" ,"MADISON AVE" ,"MADISON LN" ,"E MAIN ST" ,"MALCOLM CRESCENT" ,"MANILA ST" ,"MAPLE ST" ,"MARIE PL" ,"MARION CT" ,"W MARKET ST" ,"MARSHALL ST" ,"MARTIN ST" ,"MASON LN" ,"MASON ST" ,"MASSIE RD" ,"MAURY AVE" ,"MAYWOOD LN" ,"MCELROY DR" ,"MCINTIRE RD" ,"MEADE AVE" ,"MEADOW ST" ,"MEADOWBROOK CT" ,"MEADOWBROOK RD" ,"MEADOWBROOK HTS RD" ,"MEGAN COURT" ,"MELBOURNE PARK CIR" ,"MELBOURNE RD" ,"MELISSA PL" ,"MERIDIAN ST" ,"MERIWETHER ST" ,"MICHIE DR" ,"MIDDLETON LN" ,"MIDLAND ST" ,"MIDMONT LN" ,"MILLMONT ST" ,"MINOR COURT LN" ,"MINOR RD" ,"MOBILE LN" ,"MONROE LN" ,"MONTE VISTA AVE" ,"MONTEBELLO CIR" ,"MONTICELLO AVE" ,"MONTICELLO RD" ,"MONTPELIER ST" ,"MONTROSE AVE" ,"MOORE AVE" ,"MOORE ST" ,"MOORE'S ST" ,"MORRIS PAUL CT" ,"MORRIS RD" ,"MORTON LN" ,"MOSELEY DR" ,"MOUNTAIN VIEW ST" ,"MOWBRAY PL" ,"MULBERRY AVE" ,"MYRTLE ST" ,"NALLE ST" ,"NASSAU ST" ,"NAYLOR ST" ,"NELSON DR" ,"OAKHURST CIR" ,"OAKLEAF LN" ,"OAKMONT ST" ,"OBSERVATORY AVE" ,"PAGE ST" ,"PALATINE AVE" ,"PAOLI ST" ,"PARK HILL" ,"E PARK LN" ,"W PARK LN" ,"PARK PL" ,"PARK PLAZA" ,"PARK RD" ,"PARKER PL" ,"NEWCOMB RD" ,"NORTH AVE" ,"NORTH BAKER ST" ,"OLD PRESTON AVE" ,"OLINDA DR" ,"PARKWAY" ,"PATON ST" ,"PEARTREE LN" ,"PERRY DR" ,"PETERSON PL" ,"N PIEDMONT AVE" ,"S PIEDMONT AVE" ,"PINE ST" ,"NORTH BERKSHIRE RD" ,"NORTHWOOD AVE" ,"NORTHWOOD CIR" ,"ORANGE ST" ,"ORANGEDALE AVE" ,"OTTER ST" ,"OXFORD PL" ,"OXFORD RD" ,"PINETOP RD" ,"PLATEAU RD" ,"PLYMOUTH RD" ,"POPLAR ST" ,"PORTER AVE" ,"PRESTON PL" ,"PRICE AVE" ,"PROSPECT AVE" ,"QUARRY RD"]
      domains = %w( innocent.net oux.com  SQM.net  avu.net  bph.net  ebz.net  epj.org  epx.net  ewz.net  gjm.org  gkw.net  hfo.org  jiw.net  jmd.net  KJP.NET  lby.net  nfn.biz  nno.biz  olb.net  otd.net  pzo.net  rfn.biz  rlr.net  RTY.net  rwh.net  rzp.net  sgk.net  uny.net  vaa.biz  vtj.net  vuy.net  wcy.net  wuh.net  wwo.biz  YFR.NET  ylu.net  Zfk.Net Authenticates.Com Blemishes.Org Dazed.Net Durangos.Net Excels.Net Feeds.Net Filet.Net Flings.Net Groundbreaking.Net Houseowners.Net Housesitting.Net Integrates.Com Launching.Net Liquidates.Com Party.biz Possibilities.Net Promotes.Net Prosecutes.Com Relaxing.Net Reminders.Net Softener.Net Spoken.Net Subcontracts.Net Technology.biz Thinner.Net Trained.Net Transacts.Net Translates.Net Whiten.Net accept.net animators.net arouses.net arrests.net attests.com attracts.net borrowers.net cheeseburgers.net communicator.net convenience.net crayons.net discovers.net downloads.net electrify.biz elevates.com endure.biz enforcers.net enrolled.net excited.net exposes.net ezines.net flattens.com flirting.net givers.net guides.net haggle.net innocent.net laughers.net libations.net mingle.biz moisten.net multimillionaires.net mustache.net namers.net nutritious.net overstocks.net pasttimes.net porky.net position.biz prankster.net profiteering.net prosecutors.net pursue.biz redirects.net rejuvenates.com rekindle.com relocator.net residuals.biz revenues.biz rhinestones.net snapped.net snooze.net socialize.biz specializes.net stimulates.net stogies.net surnames.biz tighten.net transact.biz tweaks.net whiteners.net Affordableroses.Com
                  Angelicarrivals.com Australianauction.Com Bargaincables.Com Buyseafood.net Campergear.Com Cigarettekingdom.com Coffeebeans.Net Coffeekingdom.Com Coffeesupremo.Com Dailywatch.Com Discountfurs.Com Discountsatellite.Com Dutchbid.Com Finedvds.Com Fruitbasket.Net Giftbasketbiz.Com Gourmetstores.Com Gucci-Watches.com Heartvitamins.Com Jewelryauction.Net Loveperfumes.Com Minervawatches.Com Motorcycletires.Biz Nicejewelry.Com Onlinedollarshop.Com Patchez.Com Plushcarpet.Com Preciousgems.Com Qualitydvds.Com Rugsales.Com Shopfinders.Com Shoppinghunt.Com Spafinder.Net Totallypearls.com Usedshops.Com Warranty.Net 4carats.com aaaflorist.com Abbeyrugs.Com amazingdvd.com Antiquejewelryauction.Com Aromaverde.Com auctionvista.com Awesomedvd.Com Awesomedvds.Com Babybedding.Net Basketsbypatty.Com beaniebeanie.com bestofdvd.com bestpricejewelrystore.com birthdaycards.net cdboulevard.com cdexperience.com cdmusicnow.com Chromerims.Net computerfinders.com cornerstores.com Customrims.Net dealbrowser.com dealdirectory.com Diamondengagmentring.Com dvddomain.com electronicsequipment.com elegantflowers.com elitewatches.com empiredvd.com Engagementring.Net everydaymoments.com fashionjewelery.com fashionwebsites.com finegiftsdepot.com finegiftshop.com finegiftshops.com Finejewelry.Net flowersandgifts.net forevergems.com Freeinternetshopping.Com gearunlimited.com Gemsngold.Com getgreatcoffee.com groceryshop.net hollywooddvds.com Itsmyshop.Com jewelryauctions.com jewelrysmart.com justaboutjewelry.com Memorablebaskets.Com Mostwantedgear.Com moviesandlotsmore.com netlobster.com OUTPOSTAUCTIONS.COM overniteroses.com palmtopshop.com PRECIOUSGIFTBASKETS.COM Premiergems.Com Printacalendar.Com rarehumidors.com realmeals.com Recreationvehicles.Net searchdeals.com shoppinggems.com shoppingjewelry.com Shoppingpedia.Com shoptron.com superbshopping.com superlowprice.com Truckaccesories.Net Truckrims.Net ultimatebid.com usjewels.com valentinegoodies.com Verticalblinds.Net vintagereserve.com virtualvaluables.com wecaregiftshop.com winbid.com )
      first_names = %W(LUCAS THEO THOMAS HUGO MAXIME ENZO ANTOINE CLEMENT ALEXANDRE QUENTIN LEA MANON EMMA CHLOE CAMILLE OCEANE CLARA MARIE SARAH INES)
      surnames =  %w(SMITH JOHNSON WILLIAMS JONES BROWN DAVIS MILLER WILSON MOORE TAYLOR ANDERSON THOMAS JACKSON WHITE HARRIS MARTIN THOMPSON GARCIA MARTINEZ ROBINSON CLARK RODRIGUEZ LEWIS LEE WALKER HALL ALLEN YOUNG HERNANDEZ KING WRIGHT LOPEZ HILL SCOTT GREEN ADAMS BAKER GONZALEZ NELSON CARTER MITCHELL PEREZ ROBERTS TURNER PHILLIPS CAMPBELL PARKER EVANS EDWARDS COLLINS STEWART SANCHEZ MORRIS ROGERS REED COOK MORGAN BELL MURPHY BAILEY RIVERA COOPER RICHARDSON COX HOWARD WARD TORRES PETERSON GRAY RAMIREZ JAMES WATSON BROOKS KELLY SANDERS PRICE BENNETT WOOD BARNES ROSS HENDERSON COLEMAN JENKINS PERRY POWELL LONG PATTERSON HUGHES FLORES WASHINGTON BUTLER SIMMONS FOSTER GONZALES BRYANT ALEXANDER RUSSELL GRIFFIN DIAZ HAYES MYERS FORD HAMILTON GRAHAM SULLIVAN WALLACE WOODS COLE WEST JORDAN OWENS REYNOLDS FISHER ELLIS HARRISON GIBSON MCDONALD CRUZ MARSHALL ORTIZ GOMEZ MURRAY FREEMAN WELLS WEBB SIMPSON STEVENS TUCKER PORTER HUNTER HICKS CRAWFORD HENRY BOYD MASON MORALES KENNEDY WARREN DIXON RAMOS REYES BURNS GORDON SHAW HOLMES RICE ROBERTSON HUNT BLACK DANIELS PALMER MILLS NICHOLS GRANT KNIGHT FERGUSON ROSE STONE HAWKINS DUNN PERKINS HUDSON SPENCER GARDNER STEPHENS PAYNE PIERCE BERRY MATTHEWS ARNOLD WAGNER WILLIS RAY WATKINS OLSON CARROLL DUNCAN SNYDER HART CUNNINGHAM BRADLEY LANE ANDREWS RUIZ HARPER FOX RILEY ARMSTRONG CARPENTER WEAVER GREENE LAWRENCE ELLIOTT CHAVEZ SIMS AUSTIN PETERS KELLEY FRANKLIN LAWSON FIELDS GUTIERREZ RYAN SCHMIDT CARR VASQUEZ CASTILLO WHEELER CHAPMAN OLIVER MONTGOMERY RICHARDS WILLIAMSON JOHNSTON BANKS MEYER BISHOP MCCOY HOWELL ALVAREZ MORRISON HANSEN FERNANDEZ GARZA HARVEY LITTLE BURTON STANLEY NGUYEN GEORGE JACOBS REID KIM FULLER LYNCH DEAN GILBERT GARRETT ROMERO WELCH LARSON FRAZIER BURKE HANSON DAY MENDOZA MORENO BOWMAN MEDINA FOWLER BREWER HOFFMAN CARLSON SILVA PEARSON HOLLAND DOUGLAS FLEMING JENSEN VARGAS BYRD DAVIDSON HOPKINS MAY TERRY HERRERA WADE SOTO WALTERS CURTIS NEAL CALDWELL LOWE JENNINGS BARNETT GRAVES JIMENEZ HORTON SHELTON BARRETT OBRIEN CASTRO SUTTON GREGORY MCKINNEY LUCAS MILES CRAIG RODRIQUEZ CHAMBERS HOLT LAMBERT FLETCHER WATTS BATES HALE RHODES PENA BECK NEWMAN HAYNES MCDANIEL MENDEZ BUSH VAUGHN PARKS DAWSON SANTIAGO NORRIS HARDY LOVE STEELE CURRY POWERS SCHULTZ BARKER GUZMAN PAGE MUNOZ BALL KELLER CHANDLER WEBER LEONARD WALSH LYONS RAMSEY WOLFE SCHNEIDER MULLINS BENSON SHARP BOWEN DANIEL BARBER CUMMINGS HINES BALDWIN GRIFFITH VALDEZ HUBBARD SALAZAR REEVES WARNER STEVENSON BURGESS SANTOS TATE CROSS GARNER MANN MACK MOSS THORNTON DENNIS MCGEE FARMER DELGADO AGUILAR VEGA GLOVER MANNING COHEN HARMON RODGERS ROBBINS NEWTON TODD BLAIR HIGGINS INGRAM REESE CANNON STRICKLAND TOWNSEND POTTER GOODWIN WALTON ROWE HAMPTON ORTEGA PATTON )

     invoices_number = 0
     last_invoice_date = DateTime.parse("2002-01-01")
      1.upto 100 do |i|
         company_instance = Instance.new :entity => entities["companies"]
         company_instance.save
         name = companies.delete_at(rand(companies.length))
         company_instance_name = DetailValue.new :detail => company_name.detail, :instance => company_instance, :value => name
         company_instance_name.save
         street = streets[rand(streets.length)]
         company_instance_street = DetailValue.new :detail => company_address.detail, :instance => company_instance, :value => "#{street} #{rand(1789)}"
         company_instance_street.save
         domain = domains.delete_at(rand(domains.length))
         contacts = []
         company_instance_email = EmailDetailValue.new :detail => company_email.detail, :instance => company_instance, :value => "info@#{domain}"
         company_instance_email.save
         company_instance_website = DetailValue.new :detail => company_website.detail, :instance => company_instance, :value => "http://www.#{domain}"
         company_instance_website.save
         company_instance_city = DetailValue.new :detail => company_city.detail, :instance => company_instance, :value => cities[rand(cities.length)]
         company_instance_city.save

         1.upto(rand(5)+1) do |c|
           contact = Instance.new :entity => entities["contacts"]
           contact.save
           contacts.push contact
           first_name = first_names[rand(first_names.length)].capitalize
           contact_first_name = DetailValue.new :detail => contact_first_name.detail, :instance => contact, :value => first_name
           contact_first_name.save
           surname =  surnames[rand(surnames.length)].capitalize
           contact_surname = DetailValue.new :detail => contact_surname.detail, :instance => contact, :value => surname
           contact_surname.save
           contact_phone = DetailValue.new :detail => contact_phone.detail, :instance => contact, :value => rand(1000000000)
           contact_phone.save
           contact_email = EmailDetailValue.new :detail => contact_email.detail, :instance => contact, :value => "#{first_name.downcase}.#{surname.downcase}@#{domain}"
           contact_email.save
           link = Link.new :relation => company_contact_relation, :parent => company_instance, :child => contact
           link.save
         end
         1.upto rand(25) do |inv|
           invoice = Instance.new :entity => entities["invoices"]
           invoice.save
           invoice_number  = DetailValue.new :detail => invoice_number.detail, :instance => invoice, :value => invoices_number+=1
           invoice_number.save
           last_invoice_date=last_invoice_date+rand(15)
           invoice_date = DateDetailValue.new :detail => invoice_date.detail, :instance => invoice, :value => (last_invoice_date).strftime("%F")
           invoice_date.save
           invoice_send_date = DateDetailValue.new :detail => invoice_sent_on.detail, :instance => invoice, :value => (last_invoice_date+rand(15)).strftime("%F")
           invoice_send_date.save
           invoice_paid_date = DateDetailValue.new :detail => invoice_paid_on.detail, :instance => invoice, :value => (last_invoice_date+rand(60)).strftime("%F")
           invoice_paid_date.save
           link = Link.new :relation => company_invoice_relation, :parent => company_instance, :child => invoice
           link.save
         end

         1.upto rand(20) do |com|
           communication_instance = Instance.new :entity => entities["communications"]
           communication_instance.save

           communication_instance_date = DateDetailValue.new :detail => communications_date.detail, :instance => communication_instance, :value => (last_invoice_date-rand(com*3)).strftime("%F")
           communication_instance_date.save
           communication_instance_subject = DetailValue.new :detail => communications_subject.detail, :instance => communication_instance, :value => "happy custmomer"
           communication_instance_subject.save
           communication_instance_notes = DetailValue.new :detail => communications_notes.detail, :instance => communication_instance, :value => "Customer wanted to confirm once again that they're happy with our service."
           communication_instance_notes.save

           communication_instance_contact = contacts[rand(contacts.length)]
           link = Link.new :relation => communications_contacts_relation, :parent => communication_instance , :child => communication_instance_contact
           link.save
           communication_instance_contact_company = Instance.find :first, :conditions => [ "id in (select parent_id from links where child_id=?) and entity_id=?", communication_instance_contact.id, entities["companies"].id]
           link = Link.new :relation => communications_company_relation, :parent => communication_instance , :child => communication_instance_contact_company
           link.save
         end



      end
  end
end
