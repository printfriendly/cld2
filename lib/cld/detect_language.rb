module CLD


  def self.detect_language(text,
                           plain_text: true,
                           tld: nil, # "us"
                           encoding: Encoding[:UNKNOWN_ENCODING],
                           language: Language[:UNKNOWN_LANGUAGE])
    detect(text, plain_text: plain_text, tld: tld, encoding: encoding, language: language).to_h
  end

  def self.detect(text,
                  plain_text: true,
                  tld: nil, # "us"
                  encoding: Encoding[:UNKNOWN_ENCODING],
                  language: Language[:UNKNOWN_LANGUAGE])
    detect_language_ext(text.to_s, plain_text, tld, encoding, language)
  end

  private

  class Result < FFI::Struct
    include LanguageDecoder

    layout  :lang,     Language,
            :reliable, :bool

    def lang
     self[:lang]
    end

    def reliable
      self[:reliable]
    end

    def to_h
      { lang_id: lang_id, code: code, name: name, reliable: reliable }
    end
  end

  attach_function "detect_language_ext", "detectLanguageExt", [:buffer_in, :bool, :string, Encoding, Language], Result.by_value
end
