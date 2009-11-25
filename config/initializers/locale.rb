# tell the I18n library where to find your translations
I18n.load_path += Dir[ File.join(RAILS_ROOT, 'config', 'locale', '*.{rb,yml}') ]

class Symbol # :nodoc:
  # Localizes the symbol into the current locale.
  # If there is no translation available, the replacement string will be returned
  def localize(replacement_string = '__localization_missing__', args={})
    I18n.translate(self, {:default => "#{replacement_string}"}.merge(args))
  end
  alias :l :localize
  
  def l_in(locale, args={})
    I18n.translate(self, {:locale => locale, :default => "_localization_missing_"}.merge(args)) unless locale.nil?
  end
  
  # Note that this method takes the replacement string after the args hash unlike other Globalite methods
  def localize_with_args(args={}, replacement_string = '__localization_missing__')
    sym_args = args.inject({}){|r,i| r.merge({i.first.to_sym => i.last}) }
    I18n.translate(self, {:default => "#{replacement_string}"}.merge(sym_args))
  end
  alias :l_with_args :localize_with_args
  
end


