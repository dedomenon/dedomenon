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

# The methods added to this helper will be available to all templates in the application.
module ApplicationHelper
	def show_list(options = {})
		data = { "list_id" =>  "list", "refresh_params" => nil}
    options.each do |k,v|
      data[k.to_s] = v
    end
		if options[:links]
			links = options[:links]
		else
			links =[ { "header" => "Details" , "text" => "View", "options" => {:controller => "entities",:action => "view"}, "evals" => ["id"]  },
				   { "header" => "Edit" , "text" => "Edit", "options" => {:controller => "entities",:action => "edit"}, "evals" => ["id"]  }
				   ]
		end
		if options[:instances].length <1
			render_template "rhtml", "no data to display"
      data["instances"] = []
		else
			# data["list_id"] = options[:list_id] if options[:list_id]
#			paginator = ActionController::Pagination::Paginator.new self, options[:instances].length, 10, params[data["list_id"].to_s+"_page"]
#			data["paginator"] = paginator
			data["entity"] = options[:instances][0].entity
			#FIXME
			list_id = data["list_id"]
			#detail_order = "name"
      #if params["#{data["list_id"]}_order"]
      #  detail_order= params["#{data["list_id"]}_order"]
      #  options[:instances].sort!{ |x,y| x.detail_value(detail_order).downcase<=>y.detail_value(detail_order).downcase }
      #end
			#data["instances"]=options[:instances][paginator.current_page.first_item-1..paginator.current_page.last_item-1]
			#data["instances"]=options[:instances]
			data["links"] = links

      if options[:type] == "parents"
        type_id="child_id"
      else
        type_id="parent_id"
      end
			data["links"].push({"header" => "Unlink" , "text" => "Unlink", "ajax" => true, "options" => {:controller => "entities",:action => "unlink", type_id.to_sym=>params["id"], :relation_id => options[:relation_id] }, "evals" => [ "id"] }) if options[:destroy_link]==true

		end
    render file => "/entities/list_template", :locals => data
	end

  def form_hidden_fields(h)
    s=""
    h.each do |k,v|
      next if v=="" or v==nil
      s += %Q{<input type="hidden" name="#{k.to_s}" value="#{v}">}
    end
    return s
  end

  def form_integer_select(n, selected=nil)
    s=""
    #1.upto(n) { |i| s+=%Q{<option value="#{i}">#{i}</option>} }
    1.upto(n) { |i| s+=%Q{<option #{i==selected.to_i ? "selected=":"" } value="#{i}">#{i}</option>} }
    return s
  end

  def help_info(s)
    if (session["user"].preference and !session["user"].preference.display_help?)
      return ""
    else
      return %{<div class="help"><span class="title">&lt; #{t("madb_help") } ! &gt;</span>#{t(s)}<br>#{t("madb_help_info_you_can_disable_help_in_your_settings")}</div>}
    end
  end

  class YuiBlock < BlockHelpers::Base
    # options:
    # :modules => { "gallery-forms" => { :fullpath => "http://....", :requires => ['node', 'attribute'], :optional => [], :supersedes => []} }
    # :use => [ 'gallery-forms', 'console']
    # :console => true

    def initialize(options = {})
      #used for development
      #@modules = { "gallery-form" => { :fullpath => "http://#{AppConfig.app_host}/javascripts/yui3-gallery/build/gallery-form/gallery-form-debug.js", :requires => ['node', 'attribute', 'widget', 'io-form', 'substitute', 'io-upload-iframe'], :optional => [], :supersedes => []}, "madb" => { :fullpath => "http://#{AppConfig.app_host}/app/dyn_js/madb_yui.js", :requires => ['io-base', 'io-xdr','gallery-form']  }} 
      # this uses the gallery-form in myowndb's repository
      @modules = { "gallery-form" => { :fullpath => "http://#{AppConfig.app_host}/javascripts/gallery-form/gallery-form#{RAILS_ENV=="development" ? "-debug" : "-min"}.js", :requires => ['node', 'attribute', 'widget', 'io-form', 'substitute', 'io-upload-iframe'], :optional => [], :supersedes => []},
                   "gallery-yui2" => { :fullpath => "http://yui.yahooapis.com/gallery-2009.11.19-20/build/gallery-yui2/gallery-yui2#{RAILS_ENV=="development" ? "-debug" : "-min"}.js", :requires => ['node-base','get','async-queue'], :optional => [], :supersedes => []},
                    "madb" => { :fullpath => "http://#{AppConfig.app_host}/app/dyn_js/madb_yui.js", :requires => ['io-base', 'io-xdr','gallery-form']  },
                    "madb-tables" => { :fullpath => "http://#{AppConfig.app_host}/app/dyn_js/entities_table.js", :requires => ['substitute', 'gallery-yui2', 'madb', 'io-base', 'event-key', 'widget']  } } 
      #build string passed to YUI
      inits = []
      options[:modules].each do |m| 
        init =""
        if m.kind_of? Array
          module_name = m[0]
          module_spec = m[1]
        else
          module_name = m
          module_spec = @modules[m]
        end
        init+= "\"#{module_name}\" : "
        init+=module_spec.inject("{"){|a,k| a+'"'+k[0].to_s+'":'+ k[1].to_json.chomp+',' }.chop
        init+= "}"
        inits.push init
        
      end
        init= "{ modules : { #{inits.join(',')} }}"
      #build options passed to use()
      options[:use].push('console') if options[:console] == true #or RAILS_ENV=="development"
      use = ""
      use += options[:use].collect{|u| '"'+u.to_s+'"'}.join(',')

      @yui_init = "YUI(#{init}).use(#{use}, function(Y) {"
      @yui_init += "new Y.Console().render();" if options[:console] ==true # or RAILS_ENV=="development" 
    end
    def display(body)
      "#{@yui_init} #{body} }); "
    end
  end
# 
#<% yui_block( :modules => { "gallery-forms" => { :fullpath => "http://yui.yahooapis.com/gallery-2009.12.08-22/build/gallery-form/gallery-form-min.js", :requires => ['node', 'attribute', 'widget', 'io-form', 'substitute'], :optional => [], :supersedes => []} }, :use => [ 'gallery-forms', 'console']) do %>
#alert("hello");
#<% end %>

#<% yui_block( :modules => [ "gallery-forms" ], :use => [ 'gallery-forms', 'console']) do %>
#alert("hello");
#<% end %>
#

  def entities_table(h={})
    raise "Missing options" if h[:controller].nil? or h[:entity].nil? or h[:content_box].nil? or h[:js_var].nil?
    entity = h[:entity]
    js = %{
       var #{h[:js_var]} = new Y.madb_tables.EntitiesTable({column_headers: [ #{ entity.details_in_list_view.collect{|d| d.yui_column(:controller => h[:controller])  }.join(',') } , {"key": "id", "hidden": true}  ] ,
                  source_url: "#{url_for :controller => "entities", :action => "entities_list", :format => "js", :id => entity  }?",
                  fields_definition : [ #{ entity.details_in_list_view.collect{|d| d.yui_field(:controller => h[:controller] )  }.join(',') } ],
                  entity_name: '#{ entity.name}',
                  entity_id : #{ entity.id },
                  filter_options : '#{ options_for_select(entity.ordered_details.collect{|d| [ d.name, d.detail_id]}).gsub(/\n/,'') }', 
                  contentBox: '#{h[:content_box]}'});
       #{h[:js_var]}.render();
    }
  end
  #default entity form
  def default_entity_form(h)
   (h[:form_content_box] ) or raise "need :form_content_box passed"
   h[:upload]=false if h[:upload].nil?
   h[:success_callback] ='function(form,data){}'  if h[:success_callback].nil?

   #listen to complete event if this is an upload form
   #listent to success for normal forms
   event_to_watch = (h[:upload] ? "complete" : "success")

   js = %{
     

     
//We add validation on all fields. 
//If no validator was specified for the detail (see in model), 
//the default one is used, accepting all values.
//If a validator was defined with YUI.madb.get_detail_validator, it will be used.
    Y.Array.each(fields,
      function(field,i,a) { 
        if (field.on)
        {
          field.on('blur', Y.bind( function(e) {
            this.validateField();
            }, field));
        }
    });
     
     f = new Y.Form({
      id:"test",
        contentBox: '##{h[:form_content_box]}',
        action : '#{url_for :controller => :entities, :action=> "apply_edit"}',
        method : 'post',
        upload : #{h[:upload]},
        resetAfterSubmit: false,
        skipValidationBeforeSubmit: true,
        fields : fields
    });
 
    f.subscribe('#{event_to_watch}', function (args) {
	var data = args.response.responseText;
	if (data.match(/(.{8}_([\\w\\s]+_[\\w\\s]*)\\[\\d\](_\\w+)*(######)?)+/))
	{
	    var invalid_fields = YAHOO.util.Dom.getElementsByClassName('invalid_form_value', 'input',this.form); 
	    try {
	    YAHOO.util.Dom.batch(invalid_fields, function (e) {Element.removeClassName( e,'invalid_form_value');Element.addClassName( e,'unchecked_form_value'); });
	    }
	    catch(e)
	    {
	    }
	  ids = data.split('######');
	  //<%# comment needed for test code
	  //%>
	  for(var i=0;i</*>*/ids.length; i++)
	  {
	      value = ids[i];

              YAHOO.util.Dom.removeClass( value,'valid_form_value');
              YAHOO.util.Dom.removeClass( value,'unchecked_form_value');
              YAHOO.util.Dom.addClass( value,'invalid_form_value');
	  }
	}
	else if (data.match(/__ERROR__.*/))
	{
	  message = data.replace('__ERROR__','');
	  alert(message);
	}
	else
	{
         var callback =  #{h[:success_callback]} ;
         callback(f,data);
        }
    });
    f.subscribe('failure', function (args) {
        alert('Form submission failed');
    });}

    return js

  end

  def update_list_form_callback(list_id)

        js= %{  
          function(form,data)
          {
          var list_div = Y.one("##{list_id}_div");
          list_div.set('innerHTML',data);
          var highlighted_row = list_div.one("tr.highlight");
          var anim = new Y.Anim({ node: highlighted_row, from: { backgroundColor: '#FFFF33' }, to : { backgroundColor: '#fff' }, duration: 2 } );
          anim.run();

          f._formNode.all('input.invalid_form_value').removeClass('invalid_form_value').addClass('unchecked_form_value');
          Effect.Fade('xhr_message',{duration:0.5,queue:'end'});
          }
        }

        return js
  end


end
