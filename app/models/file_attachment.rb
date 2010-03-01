## We define these contants in the model to  minizie the change 

# *Description*
#     Contains the S3 Attachment. Stored in the +detail_value+ table.
#     See +DetailValue+ for details.
#     
# *Relationships*
#     * belongs_to :instance
#     * belongs_to :detail   
# 
class FileAttachment < DetailValue
  storage_type = AppConfig.file_attachment_storage
  require "#{ storage_type }_attachment_module.rb"
  storage_module = eval "FileAttachmentModule::#{storage_type.classify}Storage"
  include storage_module 

  belongs_to :instance
  belongs_to :detail
  serialize :value  #for file_name, mimetype, bucket and key
  
        
  def self.table_name
    "detail_values"
  end

  # *Description*
  #   Here we connect to the S3 AWS through the KEY ID and Key
  def initialize(*args)
    super(*args)
  end

  # This returns true always. Just a work around to get ready for the production
  def allows_upload?
    return true
  end

  # Same as before
  def allows_download?
    return true
  end

  def account_id 
    self.instance.entity.database.account_id
  end
  
  def database_id
    self.instance.entity.database_id
  end
  
  def entity_id  
    self.instance.entity_id
  end

  def value=(v)
    if v.kind_of?(Hash)
      h = v 
    else
      @attachment = v
      h = { :filename => File.basename(v.original_filename), :filetype => v.content_type, :uploaded => false}
    end
    write_attribute(:value, h)
  end
  def to_form_row(i=0, o = {})
    #entity_input is used for the id of the input containing the field
    #we need to add random characters to the entity name so scripts generated can distinguish fields in a form
     entity_input = %Q{#{o[:form_id]}_#{o[:entity].name}}.gsub(/ /,"_")
     entity = entity_input+"_"+String.random(3)
		 id = detail.name+"["+i.to_s+"]"
    if allows_upload?
      replace_icon=%Q{<img id="replace_file_#{entity}_#{id}" class="action_cell" src="/images/icon/big/edit.png" alt="replace_file"/>}
      input_field = %Q{<input type="hidden" id="#{o[:entity].name}_#{detail.name}[#{i.to_s}]_id" name="#{detail.name}[#{i.to_s}][id]" value="#{self.id}"><input detail_id="#{detail.id}" class="unchecked_form_value" type="file" id ="#{entity_input}_#{id}_value" name="#{id}[value]"/>}
      undo_icon = %Q{<img onclick="undoFileUpload_#{entity}_#{i}();" id="undo_file_#{entity}_#{id}" class="action_cell" src="/images/icon/big/undo.png" alt="undo_replace_file"/>}
     upload_file_function = %Q{function displayFileUpload_#{entity}_#{i}(e, reversible)
       {
         file_cell = $('#{entity}_#{id}_cell');
            YAHOO.madb.container["#{entity}_#{id}_original_value"] = file_cell.innerHTML;
            YAHOO.util.Event.addListener("undo_file_#{entity}_#{id}",'click',undoFileUpload_#{entity}_#{i});
            var content = '#{input_field}';
            if (reversible)
            {
              content=content+'#{undo_icon}';
            }
            file_cell.innerHTML= content;
            YAHOO.madb.upload_field_tooltips_#{entity}_#{i}();
            YAHOO.madb.hide_current_file_tooltips_#{entity}_#{i}();
       }
       }
    else
      replace_icon="#{self.class.no_transfer_allowed_icon}"
      input_field ="#{self.class.no_transfer_allowed_icon}"
     upload_file_function = %Q{function displayFileUpload_#{entity}_#{i}(e, reversible)
       {
         file_cell = $('#{entity}_#{id}_cell');
         file_cell.innerHTML= '<img src="/images/icon/big/error.png" alt="no_upload" id="no_upload_icon_#{entity}_#{id}">';
         new YAHOO.widget.Tooltip("no_upload_tooltip_#{entity}_#{id}", {  
                       context:"no_upload_icon_#{entity}_#{id}",  
                       text:YAHOO.madb.translations['madb_file_transfer_quota_reached'], 
                       showDelay:100,
                       hideDelay:100,
                       autodismissdelay: 20000} ); 

         }
       }
    end
     #idof the hidden field containing the id of this detail_value, used later in the javascript to reset the value of the hidden field whe we delete the attachment.
     hidden_field_id = %Q{#{o[:entity].name}_#{detail.name}[#{i.to_s}]_id} 
     if value.nil?
      return %Q{<tr><td>#{detail.name}:</td><td id="#{entity}_#{id}_cell">#{input_field}</td></tr> }
     else
      return %Q{
      <tr><td>#{detail.name}:</td><td id="#{entity}_#{id}_cell">#{value[:filename]}<img id="delete_file_#{entity}_#{id}" class="action_cell" src="/images/icon/big/delete.png" alt="delete_file"/>#{replace_icon}</td></tr><script type="text/javascript">

  YAHOO.madb.upload_field_tooltips_#{entity}_#{i} =  function() {
      YAHOO.madb.undo_tooltip_#{entity}_#{i} = new YAHOO.widget.Tooltip("undo_file_tooltip_#{entity}_#{id}", {  
           context:"undo_file_#{entity}_#{id}",  
           text:YAHOO.madb.translations['madb_go_back_do_no_replace_current_file'], 
           showDelay:100,
           hideDelay:100,
           autodismissdelay: 20000} ); 
  }

  YAHOO.madb.hide_current_file_tooltips_#{entity}_#{i} =  function() { 
      YAHOO.madb.delete_tooltip_#{entity}_#{i}.hide();
      YAHOO.madb.replace_tooltip_#{entity}_#{i}.hide();
  }

  YAHOO.madb.hide_upload_field_tooltips_#{entity}_#{i} =  function() { 
      YAHOO.madb.undo_tooltip_#{entity}_#{i}.hide();
  }

  YAHOO.madb.current_file_tooltips_#{entity}_#{i} =  function() { 
      YAHOO.madb.delete_tooltip_#{entity}_#{i} = new YAHOO.widget.Tooltip("delete_file_tooltip_#{entity}_#{id}", {  
           context:"delete_file_#{entity}_#{id}",  
           text:YAHOO.madb.translations['madb_delete_file'], 
           showDelay:100,
           hideDelay:100,
           autodismissdelay: 20000} ); 
      YAHOO.madb.replace_tooltip_#{entity}_#{i} = new YAHOO.widget.Tooltip("replace_file_tooltip_#{entity}_#{id}", {  
           context:"replace_file_#{entity}_#{id}",  
           text:YAHOO.madb.translations['madb_replace_file'], 
           showDelay:100,
           hideDelay:100,
           autodismissdelay: 20000} ); 
  }
  YAHOO.madb.current_file_tooltips_#{entity}_#{i}();

   YAHOO.util.Event.addListener("replace_file_#{entity}_#{id}",'click',displayFileUpload_#{entity}_#{i}, true);
   YAHOO.util.Event.addListener("delete_file_#{entity}_#{id}",'click',delete_file_#{entity}_#{i});

  function delete_file_#{entity}_#{i}()
  {
    var callback ={ success: function(o) {
                    displayFileUpload_#{entity}_#{i}(null, false);
                    if (document.getElementById('#{hidden_field_id}')!=null) 
                      {
                        document.getElementById('#{hidden_field_id}').setAttribute('value','');
                      }
                  },
                    failure: function(type, error){ alert(error.message) }
    }
                        

    var url = "#{o[:controller].url_for(:controller => "detail_values", :action =>"delete", :id => self.id )}";
    YAHOO.util.Connect.asyncRequest('POST', url, callback, null);

  }

  #{upload_file_function}
   function undoFileUpload_#{entity}_#{i}()
     {
          $('#{entity}_#{id}_cell').innerHTML =           YAHOO.madb.container["#{entity}_#{id}_original_value"];
          YAHOO.util.Event.addListener("replace_file_#{entity}_#{id}",'click',displayFileUpload_#{entity}_#{i}, true);
          YAHOO.util.Event.addListener("delete_file_#{entity}_#{id}",'click',delete_file_#{entity}_#{i});
          YAHOO.madb.current_file_tooltips_#{entity}_#{i}();
          YAHOO.madb.hide_upload_field_tooltips_#{entity}_#{i}();
     }
     </script>
      }
     end
    #else #no transfer allowed
    #  return %Q{<tr><td>#{detail.name}:</td><td id="#{entity}_#{id}_cell">#{value ? value[:filename] : ""}#{self.class.no_transfer_allowed_icon}</td></tr> }
    #end
	end

	def to_yui_form_row(i=0,o={})
         entity = %Q{#{o[:form_id]}_#{o[:entity].name}}.gsub(/ /,"_")
         id = detail.name+"["+i.to_s+"]"
	   %Q{
    var file_field = new Y.MadbFileField({
                  id: "#{form_field_id(i,o)}_id",
                  name:"#{form_field_name(i,o)}",
                  deleteURL:"#{o[:controller].url_for(:controller => "detail_values", :action =>"delete", :id => self.id )}",
                  value:"#{value.nil? ? '' : value[:filename]}",
                  detailValueId: "#{self.id}",
                  localizedStrings: { delete_file_confirmation: "#{ t('madb_delete_file_confirmation')}"},
                  transferAllowed: "#{allows_upload?.to_s}",
                  label:"#{form_field_label}"});
    fields.push(file_field);
            }
        end
        
                        


  def self.no_transfer_allowed_icon
    img_id = String.random(8)
    %Q{<img src="/images/icon/big/error.png" id="#{img_id}" alt="quota_reached">
    <script type="text/javascript">
      new YAHOO.widget.Tooltip("tooltip_#{img_id}", {  
           context:"#{img_id}",  
           text:YAHOO.madb.translations['madb_file_transfer_quota_reached'], 
           showDelay:100,
           hideDelay:100,
           autodismissdelay: 20000} ); 
    </script>
    }
  end

  

  def self.valid?(v, o )
    
    # Same as for allows_upload? and allows_download? methods
    #account = o[:entity].database.account
    #return false if (v and v.size > account.account_type.maximum_file_size) or !account.allows_upload?
    return true
  end
    def self.format_detail(options)
      return "" if options[:value].nil?
      options[:format] = :html if options[:format].nil?
      begin
        o = YAML.load(options[:value])
      rescue TypeError,ArgumentError
        o= options
      end
      case options[:format]
      when :html
         #detail_value_id = o[:s3_key].scan(/([^\/]+)/).last[0]
         detail_value_id = detail_value_id(o)

         #generator = S3::QueryStringAuthGenerator.new(AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
         #generator.expires_in = 60
         #url = generator.get(@@bucket_name, o[:s3_key])
         v = self.find(detail_value_id)
         if v.allows_download?
          url=options[:controller].url_for :controller => 'file_attachments', :action => 'download', :id => detail_value_id
          return %Q{<a href="#{url}">#{html_escape(o[:filename])}</a>}
         else
            html_escape(o[:filename])+self.no_transfer_allowed_icon
         end
      when :first_column
        return o[:filename]
      when :csv
        return o[:filename]
      end
    end

    def self.detail_value_id(o)
      o[:detail_value_id]
    end

    def self.yui_formatter(h={})
      %{function(cell, record, column, data) {
      if (data.filename)
        s = '<a href="#{h[:controller].url_for(:controller =>  "file_attachments", :action => "download")}/'+data.detail_value_id+'">'+data.filename+'</a>';
      else
        s = '';
      cell.innerHTML= s;
      } }
    end

  def self.yui_sortable(h={})
    "false"
  end

end
