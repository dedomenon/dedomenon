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

    def initialize(options = {})
      @modules = { "gallery-form" => { :fullpath => "http://yui.yahooapis.com/gallery-2009.12.08-22/build/gallery-form/gallery-form-min.js", :requires => ['node', 'attribute', 'widget', 'io-form', 'substitute'], :optional => [], :supersedes => []}} 
      #build string passed to YUI
      init = ""
      options[:modules].each do |m| 
        if m.kind_of? Array
          module_name = m[0]
          module_spec = m[1]
        else
          module_name = m
          module_spec = @modules[m]
        end
        init = "{'#{module_name}' : "
        init+=module_spec.inject("{"){|a,k| a+k[0].to_s+':'+ k[1].to_json.chomp+',' }.chop
        init+= "}}"
        
      end
        init= "{ modules : #{init}}"
      #build options passed to use()
      use = ""
      use += options[:use].collect{|u| '"'+u.to_s+'"'}.join(',')
      @yui_init = "YUI(#{init}).use(#{use}, function(Y) {"
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
end
