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
