# coding: utf-8

require "cld/version"
require "ffi"

module CLD
  extend FFI::Library


  # Workaround FFI dylib/bundle issue.  See https://github.com/ffi/ffi/issues/42
  suffix = if FFI::Platform.mac?
    'bundle'
  else
    FFI::Platform::LIBSUFFIX
  end

  ffi_lib File.join(File.expand_path(File.dirname(__FILE__)), '..', 'ext', 'cld', 'libcld2.' + suffix)
end

require "cld/encoding.rb"
require "cld/language.rb"
require "cld/detect_language.rb"
require "cld/detect_language_summary.rb"