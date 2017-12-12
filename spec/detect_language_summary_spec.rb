require "language_spec_helper"

describe CLD do
  describe ".detect_language_summary" do
    it_behaves_like "language detection method", :detect_language_summary

    describe ":top_langs attribute" do
      context "when multiple languages are detected" do
        subject { CLD.detect_language_summary('今天是來最偉大的一天。 Time to do some amazing work and kick some asses!  私の友達を始めましょう。')[:top_langs] }

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

        it 'has internal scores' do
          subject.each{|lang| expect(lang[:score]).to be > 1.0}
        end

        it 'has percents representing the amount of text found in each detected language' do
          subject.each{|lang| expect(lang[:percent]).to be > 25}
        end
      end

      context "when a single language is detected" do
        subject { CLD.detect_language_summary('Hola mi amigo, ¡hoy va a ser épico!')[:top_langs] }

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

        it 'has internal score' do
          expect(subject[0][:score]).to be > 1.0
        end

        it 'has percent representing the amount of text found in the detected language' do
          expect(subject[0][:percent]).to be > 90
        end
      end

      context "when a unknown language are detected" do
        subject { CLD.detect_language_summary('(*(&*&%%&%')[:top_langs] }
        it { expect(subject.size).to eq 0 }
      end
    end
  end
end