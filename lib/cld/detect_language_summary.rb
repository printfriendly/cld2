module CLD

  # Max number of detected languages returned by CLD. Currently 3.
  MAX_CLD_RESULTS = 3

  def self.detect_language_with_summary(text,
                                        plain_text: true,
                                        content_language: nil, # "us,en"
                                        tld: nil,              # "us"
                                        encoding: Encoding[:UNKNOWN_ENCODING],
                                        language: Language[:UNKNOWN_LANGUAGE])
      summary = detect_with_summary(text,
                  plain_text: plain_text,
                  content_language: content_language,
                  tld: tld,
                  encoding: encoding,
                  language: language)
      result = summary.result
      summary.delete!
      result
  end

  def self.detect_language_with_full_summary(text,
                                             plain_text: true,
                                             content_language: nil, # "us,en"
                                             tld: nil,              # "us"
                                             encoding: Encoding[:UNKNOWN_ENCODING],
                                             language: Language[:UNKNOWN_LANGUAGE])
    summary = detect_with_summary(text,
                plain_text: plain_text,
                content_language: content_language,
                tld: tld,
                encoding: encoding,
                language: language)
    result = summary.result(text)
    summary.delete!
    result
  end


  # Returns a summary reference object.
  # The #delete! method must be called when the summary object is no longer used,
  # or there will be memory leaks.
  # Use CLD.detect_language_with_summary or CLD.detect_language_with_full_summary to
  # prevent explicity memory management as those methods copies the content of the
  # summary object into a Hash and frees the memory immediately.
  def self.detect_with_summary(text,
                               plain_text: true,
                               content_language: nil, # "us,en"
                               tld: nil,              # "us"
                               encoding: Encoding[:UNKNOWN_ENCODING],
                               language: Language[:UNKNOWN_LANGUAGE])
    summary = detect_language_summary_ext(text, plain_text, content_language, tld, encoding, language)
    summary
  end

  private

  class SummaryResultReference < FFI::Struct
    layout  :lang, :int,
            :name, :string,
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
        lang: self[:lang],
        name: self[:name],
        code: self[:code],
        reliable: self[:reliable],
        top_langs: top_languages,
        num_chunks: self[:num_chunks]
      }
      r[:chunks] = chunks(original_text) if original_text
      r
    end

    def delete!
      CLD.free_summary_result(pointer)
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
        lang: chunk[:lang],
        code: chunk[:code],
        content: original_text.byteslice(chunk[:offset], chunk[:bytes])}
      }
    end

    private

    def self.get_array_from_ptr(arr_ptr, arr_size, class_type)
      [*0..(arr_size - 1)].map {|i| class_type.new(arr_ptr + (i * class_type.size))}
    end
  end

  class LanguageResult < FFI::Struct
    layout  :lang, :int,
            :code, :string,
            :percent, :int,
            :score, :double
  end

  class Chunk < FFI::Struct
    layout  :lang, :int,
            :offset, :int,
            :bytes, :uint16,
            :code, :string
  end

  attach_function "detect_language_summary_ext", "detectLanguageSummaryExt", [:buffer_in, :bool, :string, :string, Encoding, Language], SummaryResultReference.by_ref
  attach_function "free_summary_result", "freeSummaryResult", [:pointer], :void
end
