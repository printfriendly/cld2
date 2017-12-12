# encoding: UTF-8
require "language_spec_helper"

describe CLD do
  describe '.detect_langauge' do
    it_behaves_like 'language detection method', :detect_language
  end
end
