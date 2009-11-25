AppConfig.plugins.each do |plugin|
  I18n.load_path += Dir[ File.join(RAILS_ROOT, 'vendor','plugins', plugin[:name].to_s, 'config', 'locales', '*.{rb,yml}') ]
end

