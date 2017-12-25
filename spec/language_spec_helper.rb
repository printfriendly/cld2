require 'spec_helper'

shared_examples 'language detection method' do |detection_method|
  context "English text" do
    subject { CLD.send(detection_method, "This is a test") }

    it { expect(subject[:lang_id]).to eq CLD::Language[:ENGLISH] }
    it { expect(subject[:name]).to eq "ENGLISH" }
    it { expect(subject[:code]).to eq "en" }
    it { expect(subject[:reliable]).to be true }
  end

  context "French text" do
    subject { CLD.send(detection_method, "plus ça change, plus c'est la même chose") }

    it { expect(subject[:lang_id]).to eq CLD::Language[:FRENCH] }
    it { expect(subject[:name]).to eq "FRENCH" }
    it { expect(subject[:code]).to eq "fr" }
    it { expect(subject[:reliable]).to be true }
  end

  context "Italian text" do
    subject { CLD.send(detection_method, "sono tutti pazzi qui") }

    it { expect(subject[:lang_id]).to eq CLD::Language[:ITALIAN] }
    it { expect(subject[:name]).to eq "ITALIAN" }
    it { expect(subject[:code]).to eq "it" }
    it { expect(subject[:reliable]).to be true }
  end

  context "French in HTML - using CLD html " do
    subject { CLD.send(detection_method, "<html><head><body><script>A large amount of english in the script which should be ignored if using html in detect_language.</script><p>plus ça change, plus c'est la même chose</p></body></html>", plain_text: false) }

    it { expect(subject[:lang_id]).to eq CLD::Language[:FRENCH] }
    it { expect(subject[:name]).to eq "FRENCH" }
    it { expect(subject[:code]).to eq "fr"  }
  end
  context "French in HTML - using CLD text " do
    subject { CLD.send(detection_method, "<html><head><body><script>A large amount of english in the script which should be ignored if using html in detect_language.</script><p>plus ça change, plus c'est la même chose</p></body></html>", plain_text: true) }

    it { expect(subject[:lang_id]).to eq CLD::Language[:ENGLISH] }
    it { expect(subject[:name]).to eq "ENGLISH"  }
    it { expect(subject[:code]).to eq "en"  }

  end

  context "Simplified Chinese text" do
    subject { CLD.send(detection_method, "你好吗箭体") }

    it { expect(subject[:lang_id]).to eq CLD::Language[:CHINESE] }
    it { expect(subject[:name]).to eq "Chinese"  }
    it { expect(subject[:code]).to eq "zh"  }
  end

  context "Traditional Chinese text" do
    subject { CLD.send(detection_method, "你好嗎繁體") }

    it { expect(subject[:lang_id]).to eq CLD::Language[:CHINESE_T] }
    it { expect(subject[:name]).to eq "ChineseT"  }
    it { expect(subject[:code]).to eq "zh-Hant"  }
  end

  context "Unknown text" do
    subject { CLD.send(detection_method, "") }

    it { expect(subject[:lang_id]).to eq CLD::Language[:UNKNOWN_LANGUAGE] }
    it { expect(subject[:name]).to eq "Unknown"  }
    it { expect(subject[:code]).to eq "un"  }
    it { expect(subject[:reliable]).to_not be true }
  end

  context "nil for text" do
    subject { CLD.send(detection_method, nil) }

    it { expect(subject[:name]).to eq("Unknown") }
    it { expect(subject[:code]).to eq("un") }
    it { expect(subject[:reliable]).to_not be true }
  end
end

shared_examples 'detected language attribute' do |attribute|
  context "when multiple languages are detected" do
    subject { CLD.detect_language_summary('今天是來最偉大的一天。 Time to do some amazing work and kick some asses!  私の友達を始めましょう。')[attribute] }

    it { expect(subject.size).to eq 3 }

    it 'contains the correct lang_ids' do
      codes = subject.map{|lang| lang[:lang_id]}
      expect(codes).to include CLD::Language[:CHINESE_T]
      expect(codes).to include CLD::Language[:ENGLISH]
      expect(codes).to include CLD::Language[:JAPANESE]
    end

    it 'contains the correct language codes' do
      codes = subject.map{|lang| lang[:code]}
      expect(codes).to include 'zh-Hant'
      expect(codes).to include 'en'
      expect(codes).to include 'ja'
    end

    it 'contains the correct language names' do
      names = subject.map{|lang| lang[:name]}
      expect(names).to include 'ChineseT'
      expect(names).to include 'ENGLISH'
      expect(names).to include 'Japanese'
    end
  end

  context "when a single language is detected" do
    subject { CLD.detect_language_summary('Hola mi amigo, ¡hoy va a ser épico!')[attribute] }

    it { expect(subject.size).to eq 1 }

    it 'contains the correct lang_id' do
      expect(subject[0][:lang_id]).to eq CLD::Language[:SPANISH]
    end

    it 'contains the correct language code' do
      expect(subject[0][:code]).to eq 'es'
    end

    it 'contains the correct language name' do
      expect(subject[0][:name]).to eq 'SPANISH'
    end
  end

  context "when a unknown language are detected" do
    subject { CLD.detect_language_summary('(*(&*&%%&%')[attribute] }
    it { expect(subject.size).to eq 0 }
  end
end