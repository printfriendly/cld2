module CLD

  # Max number of detected languages returned by CLD. Currently 3.
  MAX_CLD_RESULTS = 3

  def self.detect_language_with_summary(text,
                                        plain_text: true,
                                        content_language: nil, # "us,en"
                                        tld: nil,              # "us"
                                        encoding: Encoding[:UNKNOWN_ENCODING],
                                        language: Language[:UNKNOWN_LANGUAGE])
    detect_with_summary(text,
                        plain_text: plain_text,
                        content_language: content_language,
                        tld: tld,
                        encoding: encoding,
                        language: language).result(text)
  end

  def self.detect_with_summary(text,
                               plain_text: true,
                               content_language: nil, # "us,en"
                               tld: nil,              # "us"
                               encoding: Encoding[:UNKNOWN_ENCODING],
                               language: Language[:UNKNOWN_LANGUAGE])
    detect_language_summary_ext(text, plain_text, content_language, tld, encoding, language)
  end

  private

  class SummaryResultValue < FFI::Struct
    layout  :name, :string,
            :code, :string,
            :reliable, :bool,
            :lang_results_ptr, :pointer,
            :num_chunks, :int,
            :chunks_results_ptr, :pointer

    def to_s
      result.to_s
    end

    def inspect
      result.inspect
    end

    def result(original_text=nil)
      r = {
        name: self[:name],
        code: self[:code],
        reliable: self[:reliable],
        top_langs: top_languages,
        num_chunks: self[:num_chunks]
      }
      r[:chunks] = chunks(original_text) if original_text
      r
    end

    # Reconstructs the top languages detected and their scores given a pointer to the array.
    def top_languages
      lang_arr = self.class.get_array_from_ptr(self[:lang_results_ptr], MAX_CLD_RESULTS, LanguageResult)
      lang_arr.
        select {|lang| !lang[:score].zero?}. # exclude padded values
        map {|lang| Hash[ lang.members.map {|member| [member.to_sym, lang[member]]} ]}
    end

    # Reconstructs individual chunks from the text and the top language detected for
    # each of them given a pointer to the array.
    def chunks(original_text)
      chunks_arr = self.class.get_array_from_ptr(self[:chunks_results_ptr], self[:num_chunks], Chunk)
      chunks_arr.map {|chunk| {
        content: original_text.byteslice(chunk[:offset], chunk[:bytes]),
        code: chunk[:code]}
      }
    end

    private

    def self.get_array_from_ptr(arr_ptr, arr_size, class_type)
      [*0..(arr_size - 1)].map {|i| class_type.new(arr_ptr + (i * class_type.size))}
    end
  end

  class LanguageResult < FFI::Struct
    layout  :code, :string,
            :percent, :int,
            :score, :double
  end

  class Chunk < FFI::Struct
    layout  :offset, :int,
            :bytes, :uint16,
            :code, :string
  end

  attach_function "detect_language_summary_ext", "detectLanguageSummaryExt", [:buffer_in, :bool, :string, :string, Encoding, Language], SummaryResultValue.by_value
end
