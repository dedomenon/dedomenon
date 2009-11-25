#require '../vendor/plugins/globalite/globalite'

module Translations
	def t(s, options={})
  #options can be:
  # * :vars : variables that can be used in the translation, eg the username
  # * :notes: notes to be passed to the translators
  # * :scope: The scope from which we start searching the translation
  # * :lang : the language to display is passed as option, else we look for it as usual (cookie, http prefered languages)
    
    return s if options[:lang] == "t_id" or (RAILS_ENV=="test" and ENV["TRANSLATIONS_ENV"]!="test")
    return '' if s.nil?
    
    lang = nil
    
    # If the new language is being provided in options
    # As is the case with mailings
    # Pick current langauge and set new one
    if options[:lang]
      lang = I18n.locale
      I18n.locale = options[:lang]
    end
    
    token = nil
    if options[:vars]
      token = s.to_sym.l_with_args options[:vars]
    else
      token = s.to_sym.l s.to_s
    end
    
    # If the lang was provided, set back
    if options[:lang]
      I18n.locale = lang
    end
    
    return token
    
  
	end

def set_user_lang
  lang = user_lang
  #Globalite.language = lang
  I18n.locale = lang
end

  def user_lang
    #uncomment to work in the console
    #return 'fr' if RAILS_ENV=='development'

    # A hook for now
    
    
    return cookies[TranslationsConfig.cookie_name] if cookies and cookies[TranslationsConfig.cookie_name]

    accepted_langs = request.env["HTTP_ACCEPT_LANGUAGE"]||"en"
    accepted_langs = accepted_langs.split(",")
    prefered_langs = []
    accepted_langs.each do  |l|
      parts = l.split(";")
      parts.length==1 ? weight=1 : weight = parts[1][2..-1]
      prefered_langs.push({ :complete => parts[0], :short => parts[0][0..1], :weight => weight})
    end

    #reverse sort so the prefered language is the first element of the array
    prefered_langs.sort!{|a,b| b[:weight].to_f<=>a[:weight].to_f}
    #languages = Language.find(:all).collect{|l| l.lang }
    languages = AppConfig.languages
    
    prefered_lang = nil
    prefered_langs.each do |l|
      if languages.include? l[:complete] 
        prefered_lang = l[:complete]
        break
      elsif languages.include? l[:short]
        prefered_lang = l[:short]
        break
      end
    end

    if prefered_lang.nil?
      cookies[TranslationsConfig.cookie_name]="en"
      return "en"
    else
      cookies[TranslationsConfig.cookie_name]=prefered_lang
      return prefered_lang
    end

    return cookies[TranslationsConfig.cookie_name]

  end
  
end

