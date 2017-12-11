module CLD


  def self.detect_language(text,
                           plain_text: true,
                           tld: nil, # "us"
                           encoding: Encoding[:UNKNOWN_ENCODING],
                           language: Language[:UNKNOWN_LANGUAGE])
    detect(text, plain_text: plain_text, tld: tld, encoding: encoding, language: language).result
  end

  def self.detect(text,
                  plain_text: true,
                  tld: nil, # "us"
                  encoding: Encoding[:UNKNOWN_ENCODING],
                  language: Language[:UNKNOWN_LANGUAGE])
    detect_language_ext(text.to_s, plain_text, tld, encoding, language)
  end

  private

  class ResultValue < FFI::Struct
    layout  :name, :string,
            :code, :string,
            :reliable, :bool

    def to_s
      result.to_s
    end

    def inspect
      result.inspect
    end

    def result
      {name: self[:name], code: self[:code], reliable: self[:reliable]}
    end
  end

  attach_function "detect_language_ext", "detectLanguageExt", [:buffer_in, :bool, :string, Encoding, Language], ResultValue.by_value
end
