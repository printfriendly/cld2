# coding: utf-8

require "cld/version"
require "ffi"

module CLD
  extend FFI::Library

  # Max number of detected languages returned by CLD. Currently 3.
  MAX_CLD_RESULTS = 3

  # Workaround FFI dylib/bundle issue.  See https://github.com/ffi/ffi/issues/42
  suffix = if FFI::Platform.mac?
    'bundle'
  else
    FFI::Platform::LIBSUFFIX
  end

  ffi_lib File.join(File.expand_path(File.dirname(__FILE__)), '..', 'ext', 'cld', 'libcld2.' + suffix)
  
  def self.detect_language(text, is_plain_text=true)
    result = detect_language_ext(text.to_s, is_plain_text)
    result_hash = Hash[ result.members.
      select {|member| ["name", "code", "reliable"].include? member.to_s}.
      map {|member| [member.to_sym, result[member]]} ]
    result_hash
  end

  def self.detect_language_summary(text, is_plain_text=true) 
    result_hash = detect_language(text, is_plain_text)
    result_hash[:top_langs] = get_top_languages(result[:lang_results_ptr])
    result_hash[:chunks] = get_chunk_results(result[:chunks_results_ptr], result[:num_chunks], text)
  end

  private

  class ReturnValue < FFI::Struct
    layout  :name, :string, :code, :string, :reliable, :bool,
            :lang_results_ptr, :pointer,
            :num_chunks, :int, :chunks_results_ptr, :pointer
  end
  
  class LanguageResult < FFI::Struct
    layout  :code, :string, :percent, :int, :score, :double
  end

  class Chunk < FFI::Struct
    layout  :offset, :int, :bytes, :uint16, :code, :string
  end

  def self.get_array_from_ptr(arr_ptr, arr_size, class_type)
    [*0..(arr_size - 1)].map {|i| class_type.new(arr_ptr + (i * class_type.size))}
  end

  # Reconstructs the top languages detected and their scores given a pointer to the array.
  def self.get_top_languages(lang_results_ptr)
    lang_arr = get_array_from_ptr(lang_results_ptr, MAX_CLD_RESULTS, LanguageResult)
    lang_arr.
      select {|lang| !lang[:score].zero?}. # exclude padded values
      map {|lang| Hash[ lang.members. map {|member| [member.to_sym, lang[member]]} ]}
  end

  # Reconstructs individual chunks from the text and the top language detected for
  # each of them given a pointer to the array. 
  def self.get_chunk_results(chunks_results_ptr, num_chunks, text)
    chunks_arr = get_array_from_ptr(chunks_results_ptr, num_chunks, Chunk)
    chunks_arr.map {|chunk| {
      content: text.byteslice(chunk[:offset], chunk[:bytes]),
      code: chunk[:code]}
    }
  end

  attach_function "detect_language_ext", "detectLanguageThunkInt", [:buffer_in, :bool], ReturnValue.by_value
end
