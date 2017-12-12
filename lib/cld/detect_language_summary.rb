module CLD
  def self.detect_language_summary(text,
                                   plain_text: true,
                                   content_language: nil, # "us,en"
                                   tld: nil,              # "us"
                                   encoding: Encoding[:UNKNOWN_ENCODING],
                                   language: Language[:UNKNOWN_LANGUAGE])
    detect_summary(
      text,
      plain_text: plain_text,
      content_language: content_language,
      tld: tld,
      encoding: encoding,
      language: language
     ).to_h(text)
  end

  def self.detect_summary(text,
                          plain_text: true,
                          content_language: nil, # "us,en"
                          tld: nil,              # "us"
                          encoding: Encoding[:UNKNOWN_ENCODING],
                          language: Language[:UNKNOWN_LANGUAGE])
    summary_result = detect_language_summary_ext(text, plain_text, content_language, tld, encoding, language)
    summary = Summary.new(summary_result) # copy summary_result to summary
    summary_result.delete!                # free summary_result memory
    summary                               # return copied summary
  end

  private

  class Summary
    include LanguageDecoder
    attr_reader :lang, :reliable, :top_langs, :chunks

    def initialize(ref)
      @lang      = ref[:lang]
      @reliable  = ref[:reliable]
      @top_langs = ref.top_languages.map{|lang_result| TopLanguage.new(lang_result)}
      @chunks    = ref.chunks.map{ |chunk_result| Chunk.new(chunk_result) }
    end

    def to_h(original_text=nil)
      h = {
        lang_id:   lang_id,
        reliable:  @reliable,
        top_langs: @top_langs.map(&:to_h)
      }
      h[:chunks] = chunks.map{ |chunk| chunk.to_h(original_text) } if original_text
      h
    end

    private

    class TopLanguage
      include LanguageDecoder
      attr_reader :lang, :percent, :score

      def initialize(lang_result)
        @lang    = lang_result[:lang]
        @percent = lang_result[:percent]
        @score   = lang_result[:score]
      end

      def to_h
        { lang_id: lang_id, code: code, name: name, percent: @percent, score: @score }
      end
    end

    class Chunk
      include LanguageDecoder
      attr_reader :lang, :offset, :bytes

      def initialize(chunk_result)
        @lang = chunk_result[:lang]
        @offset = chunk_result[:offset]
        @bytes = chunk_result[:bytes]
      end

      def to_h(original_text)
        { lang_id: lang_id, code: code, name: name, content: content(original_text) }
      end

      # Reconstructs individual chunk text given original text.
      def content(original_text)
        original_text.byteslice(@offset, @bytes)
      end
    end
  end

  class SummaryResult < FFI::Struct
    # Max number of detected languages returned by CLD. Currently 3.
    MAX_CLD_RESULTS = 3

    layout :lang,               Language,
           :reliable,           :bool,
           :lang_results_ptr,   :pointer,
           :num_chunks,         :int,
           :chunks_results_ptr, :pointer

    # Reconstructs the top languages detected and their scores given a pointer to the array.
    def top_languages
      CLD.get_array_from_ptr(self[:lang_results_ptr], MAX_CLD_RESULTS, LanguageResult).select { |lang|
        !lang[:score].zero? # exclude padded values
      }
    end

    # Reconstructs chunks from the text and the top language detected for
    # each of them given a pointer to the array.
    def chunks
      CLD.get_array_from_ptr(self[:chunks_results_ptr], self[:num_chunks], ChunkResult)
    end

    # SummaryResult is passed by reference, so memory must be managed manually.
    def delete!
      CLD.free_summary_result(pointer)
    end
  end

  class LanguageResult < FFI::Struct
    layout :lang,    Language,
           :percent, :int,
           :score,   :double
  end

  class ChunkResult < FFI::Struct
    layout :lang,   Language,
           :offset, :int,
           :bytes,  :uint16
  end

  def self.get_array_from_ptr(arr_ptr, arr_size, class_type)
    [*0..(arr_size - 1)].map {|i| class_type.new(arr_ptr + (i * class_type.size))}
  end

  attach_function "detect_language_summary_ext", "detectLanguageSummaryExt", [:buffer_in, :bool, :string, :string, Encoding, Language], SummaryResult.by_ref
  attach_function "free_summary_result", "freeSummaryResult", [:pointer], :void
end
