class AddIdKeyToS3Attachments < ActiveRecord::Migration
  def self.up
    if AppConfig.file_attachment_storage=='s3'
      FileAttachment.find(:all).each do |f|
        if f.value[:detail_value_id].nil? and f.value[:s3_key]
          o=f.value
          o[:detail_value_id]=o[:s3_key].scan(/([^\/]+)/).last[0]
          f.value=o
          f.save_without_s3
        end
      end
    end

  end

  def self.down
    # we don't go back
  end
end
