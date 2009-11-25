desc 'Dump a database to yaml fixtures.  Set environment variables DB and DEST to specify the target database and destination path for the fixtures.  DB defaults to development and DEST defaults to RAILS_ROOT/test/fixtures.'

task :dump_fixtures => :environment do
  path = ENV['DEST'] || "#{RAILS_ROOT}/test/fixtures"
  db   = ENV['DB']   || 'development'
  sql  = 'SELECT * FROM %s'

class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
 def table_names 
   ActiveRecord::Base.connection.select_values(<<-end_sql)
    SELECT c.relname
    FROM pg_class c
      LEFT JOIN pg_roles r     ON r.oid = c.relowner
      LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind IN ('r','')
      AND n.nspname IN ('myappschema', 'public')
      AND pg_table_is_visible(c.oid)
   end_sql
  end
end


  ActiveRecord::Base.establish_connection(db)
  ActiveRecord::Base.connection.table_names.each do |table_name|
    i = '000'
    File.open("#{path}/#{table_name}.yml", 'wb') do |file|
      file.write ActiveRecord::Base.connection.select_all(sql % table_name).inject({}) { |hash, record|
        hash["#{table_name}_#{i.succ!}"] = record
        hash
      }.to_yaml
    end
  end
end

