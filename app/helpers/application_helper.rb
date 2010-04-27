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
require 'action_view/helpers/javascript_helper'
module ApplicationHelper
  include ActionView::Helpers::JavaScriptHelper
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
      @modules = { "gallery-form" => { :fullpath => "http://#{AppConfig.app_host}/javascripts/gallery-form/gallery-form-debug.js", :requires => ['node', 'attribute', 'widget', 'io-form', 'substitute', 'io-upload-iframe'], :optional => [], :supersedes => []},
                    "madb" => { :fullpath => "http://#{AppConfig.app_host}/app/dyn_js/madb_yui.js", :requires => ['io-base', 'io-xdr','gallery-form']  },
                    "madb-tables" => { :fullpath => "http://#{AppConfig.app_host}/app/dyn_js/entities_table.js", :requires => ['substitute', 'yui2-datatable', 'yui2-paginator', 'yui2-datasource', 'yui2-connection','madb', 'io-base', 'event-key', 'widget']  } } 
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
    if entity.details_in_list_view.size==0
      return "alert('#{t("madb_this_entity_has_no_detail_displayed_in_list_view_and_this_will_show_theses_lists_as_empty")}');"
    end
    js = %{
       window.YAHOO = window.YAHOO || Y.YUI2; 
       var #{h[:js_var]} = new Y.madb_tables.EntitiesTable({column_headers: [ #{ entity.details_in_list_view.collect{|d| d.yui_column(:controller => h[:controller])  }.join(',') } , {"key": "id", "hidden": true}  ] ,
                  source: #{h[:source].nil? ? '"'+(url_for(:controller => "entities", :action => "entities_list", :format => "js", :id => entity)+"?")+'"' : h[:source].to_json  },
                  dynamic_data: #{ (h[:source].nil? or h[:source].is_a?(String) ) ? "true" : "false"  },
                  fields_definition : [ #{ entity.details_in_list_view.collect{|d| d.yui_field(:controller => h[:controller] )  }.join(',') } ],
                  entity_name: '#{ entity.name}',
                  entity_id : #{ entity.id },
                  filter_options : '#{ options_for_select(entity.ordered_details.collect{|d| [ escape_javascript(d.name), d.detail_id]}).gsub(/\n/,'') }',
                  actions: #{h[:actions].to_json} , 
                  identifier : '#{h[:content_box][1..-1]}',
                  contentBox: '#{h[:content_box]}'});
       #{h[:js_var]}.render();
    }
  end

  def datatable(h={})
    raise "Missing options" if h[:controller].nil? or h[:content_box].nil? or h[:js_var].nil? or (h[:ar_class].nil? and h[:columns].nil?)
    #buidl columns specs based on an AR object, or on the array passed as argument
    h[:display_filter]= (h[:display_filter].nil? ?  true : h[:display_filter])
    # extract columns which have a formatter specified
    formatted_columns = h[:formatters] ? h[:formatters].keys : []
    if h[:columns]
      displayed_columns = h[:columns].collect{|c| c[:key]}
      column_headers = h[:columns].to_json
    else
      displayed_columns = h[:ar_class].columns.reject {|c| ["id", "lock_version"].include?(c.name)  or c.name.match(/_id/) }.collect { |c| c.name}
      column_headers =displayed_columns.collect do  |c| 
        if formatted_columns.include?(c)
          "{ 'key' : '#{escape_javascript(c)}', formatter : #{ h[:formatters][c] }  }"
        else
          "{ 'key' : '#{escape_javascript(c)}' }"
        end
      end.push( "{key : 'id', hidden: true}" )
      column_headers = '[' + column_headers.join(',') + ']'
    end
    js = %{
       window.YAHOO = window.YAHOO || Y.YUI2; 
       var #{h[:js_var]} = new Y.madb_tables.EntitiesTable({column_headers:   #{ column_headers }   ,
                  source: #{ h[:source].to_json  },
                  dynamic_data: #{ (h[:source].nil? or h[:source].is_a?(String) ) ? "true" : "false"  },
                  fields_definition : #{ displayed_columns.to_json },
                  entity_name: Y.guid() ,
                  entity_id : 0,
                  filter_options : '#{ options_for_select(  displayed_columns ).gsub(/\n/,'') }',
                  actions: #{h[:actions].is_a?(String) ? h[:actions] : h[:actions].to_json} , 
                  identifier : '#{h[:content_box][1..-1]}',
                  contentBox: '#{h[:content_box]}',
                  display_filter: #{h[:display_filter].to_json}});
       #{h[:js_var]}.render();
    }
  end
  #default entity form
  def default_entity_form(h)
   (h[:form_content_box] ) or raise "need :form_content_box passed"
   h[:upload]=false if h[:upload].nil?
   h[:success_callback] ='function(form,data){}'  if h[:success_callback].nil?
   h[:failure_callback] ='function(form,data){}'  if h[:failure_callback].nil?
   h[:form_action] = url_for(:controller => :entities, :action=> "apply_edit") if h[:form_action].nil?

   #listen to complete event if this is an upload form
   #listent to success for normal forms
   event_to_watch = (h[:upload] ? "complete" : "success")

   js = %{
     

Y.publish('madb:entity_created', { broadcast: 2} );
     
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
        action : '#{h[:form_action]}',
        method : 'post',
        #{ h[:upload] ? " encodingType: Y.Form.MULTIPART_ENCODED," : ""}
        resetAfterSubmit: false,
        skipValidationBeforeSubmit: true,
        fields : fields
    });
 
    f.subscribe('#{event_to_watch}', function (e) {
	var data = e.args.responseText;
        Y.log("data is :");
        Y.log(data);
	if (data.match(/(form_.{8}_([\\w\\s]+_[\\w\\s]*)(_\\w+)*(######)?)+/))
	{
	    var invalid_fields = Y.all("input.invalid_form_value").removeClass('invalid_form_value').addClass('unchecked_form_value');
	  ids = data.split('######');
	  //<%# comment needed for test code
	  //%>
	  for(var i=0;i</*>*/ids.length; i++)
	  {
            //FIXME need to give id that is hte hash of the name to make it work with Y.one
	      var value = ids[i]+'_field';
              var field = Y.one('#'+value);

              field.removeClass('valid_form_value');
              field.removeClass('unchecked_form_value');
              field.addClass('invalid_form_value');
	  }
	}
	else if (data.match(/__ERROR__.*/))
	{
	  var message = data.replace('__ERROR__','');
	  alert(message);
	}
	else
	{
         var callback =  #{h[:success_callback]} ;
         callback(f,data);
        }
    });
    f.subscribe('failure', function (e) {
	var data = e.args.responseText,
            message = "",
            result;
        try{
          result = Y.JSON.parse(data);
          message = result.message;
        }
        catch (err) {
        }
        alert('#{escape_javascript(t('madb_form_submission_failed')) }:' +message);
        var callback =  #{h[:failure_callback]} ;
        callback(f,result);
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

  def new_relation_form(h)
    @source = @entity || h[:source]
    @relation_types = RelationSideType.find :all
    @entities = @source.database.entities
    @entities_for_yui_select = @entities.collect{|e| { :label => e.name, :value =>  e.id.to_s}  }
    @parent_side_edit = true
    @child_side_edit = true
    @child_ddl_options = @relation_types.collect{|rt| rt.name=="one" ?  { :label => t("madb_no_only_one_child"), :value => rt.id.to_s  } : { :label => t("madb_yes_multiple_child"), :value => rt.id.to_s }  }
    @parent_ddl_options = @relation_types.collect{|rt| rt.name=="one" ?  { :label => t("madb_no_only_one_parent"), :value => rt.id.to_s  } : { :label => t("madb_yes_multiple_parent"), :value => rt.id.to_s }  }
    if h[:parent]
      @parent = h[:parent]
      @parent_name = @parent.name
      @source_id = @parent.id
      @this_side = "parent"
      @other_side = "child"
    else
      @child = h[:child]
      @child_name = @child.name
      @source_id = @child.id
      @this_side = "child"
      @other_side = "parent"
    end
    if h[:relation]
      @relation = h[:relation]
      relation_hidden_field = %{fields.push( new Y.HiddenField({
                  id: "relation_id",
                  name:"relation_id",
                  value:'#{ @relation.id }' })); }
      @parent_side_edit = false
      @child_side_edit = false
    end

    js = %{

      var fields = [ ];
      var label_translations_hash = { parent_entity: '#{ escape_javascript(@parent_name) }', child_entity: '#{ escape_javascript(@child_name) }'  };
      var entities_options_labels = Y.JSON.parse('#{ escape_javascript(@entities_for_yui_select.inject({}){|acc,val| acc.merge( { val[:value].to_s => val[:label] } )    }.to_json)}');
      #{relation_hidden_field}
      fields.push( new Y.HiddenField({
                    id: "source_id",
                    name:"source_id",
                    value:'#{ @source_id }' }));
      fields.push( new Y.HiddenField({
                    id: "this_side_id",
                    name:'relation[#{ @this_side }_id]',
                    value:'#{ @source_id }' }));
      var entities_list =  new Y.SelectField({
                    id: "related_entity",
                    name:"relation[#{@other_side }_id]",
                    value: '#{ @relation? escape_javascript(@relation.send(@other_side+"_id").to_s): '' }',
                    choices: #{@entities_for_yui_select.to_json},
                    with_default_option: false,
                    disabled: #{@relation ? 'true' : 'false'},
                    label:'#{escape_javascript(t("madb_"+@other_side))}'})
      fields.push( entities_list );
      fields.push( new Y.TextField({
                    id: "p2c_name",
                    name:"relation[from_parent_to_child_name]",
                    value: '#{ @relation? escape_javascript(@relation.from_parent_to_child_name): '' }',
                    label: Y.madb.translate('#{escape_javascript(t("madb_from_parent_to_child_relation_name"))}', label_translations_hash ) }));
      fields.push( new Y.TextField({
                    id: "c2p_name",
                    name:"relation[from_child_to_parent_name]",
                    value: '#{ @relation? escape_javascript(@relation.from_child_to_parent_name): '' }',
                    label: Y.madb.translate('#{escape_javascript(t("madb_from_child_to_parent_relation_name"))}', label_translations_hash  ) }));


      //FIXME disable ddl unless  @parent_side_edit
      fields.push( new Y.SelectField({
                    id: "multiple_parents",
                    name:"relation[parent_side_type_id]",
                    choices: #{ @parent_ddl_options.to_json },
                    with_default_option: false,
                    value: '#{ @relation? escape_javascript(@relation.parent_side_type_id.to_s): '' }',
                    disabled: #{ @parent_side_edit ? 'false' : 'true' },
                    label: Y.madb.translate('#{escape_javascript(t("madb_can_one_child_entity_have_several_parents_question"))}', label_translations_hash  ) }));
      //FIXME disable ddl unless  @child_side_edit
      fields.push( new Y.SelectField({
                    id: "multiple_children",
                    name:"relation[child_side_type_id]",
                    choices: #{ @child_ddl_options.to_json },
                    with_default_option: false,
                    disabled: #{@child_side_edit ? 'false' : 'true'},
                    value: '#{ @relation? escape_javascript(@relation.child_side_type_id.to_s): '' }',
                    label: Y.madb.translate('#{escape_javascript(t("madb_can_one_parent_entity_have_several_children_question"))}', label_translations_hash  ) }));

      fields.push ( { type : 'submit', label : '#{ escape_javascript(t('madb_submit')) }', id: 'commit'});
      fields.push ( {type : 'button', label : '#{ escape_javascript(t('madb_done'))}',onclick : { fn : function(e) { Y.fire('madb:form_done', #{h[:js_var]});  }} });

      var #{h[:js_var]} = new Y.Form({
         id: Y.guid(),
         contentBox: '##{h[:content_box]}',
         action : '#{ url_for(:action => "add_link", :format => 'js') }',
         method : 'post',
         upload : false,
         resetAfterSubmit: false,
         skipValidationBeforeSubmit: true,
         fields : fields
         });
      #{h[:js_var]}.render();
      // Update translated labels when choice of linked entity is changed by the user
      var update_translations = function(text) {
        #{h[:js_var]}._formNode.all(".no_css_#{ @other_side }_name").setContent( text);
      }
      entities_list.on("change", function(e) { var text = entities_options_labels[e.currentTarget.get('value')];
                                               update_translations(text);       });
      // Initialize translations when page first displayed
      update_translations( entities_options_labels[entities_list.get('value')] );
      Y.on('madb:form_done', function(f) { f.get('contentBox').get('parentNode').get('parentNode').toggleClass('hidden') } );



    }
    return  js


  end


end
