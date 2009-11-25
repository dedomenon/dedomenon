class SwitchFromS3AttachmentToFileAttachment < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute("update detail_values set type='FileAttachment' where type='S3Attachment';")
    ActiveRecord::Base.connection.execute("update data_types set class_name='FileAttachment' where class_name='S3Attachment';")
  end

  def self.down
    ActiveRecord::Base.connection.execute("update detail_values set type='S3Attachment' where type='FileAttachment';")
    ActiveRecord::Base.connection.execute("update data_types set class_name='S3Attachment' where class_name='FileAttachment';")
  end
end
