require "language_spec_helper"

describe CLD do
  describe ".detect_language_summary" do
    it_behaves_like "language detection method", :detect_language_summary


    describe ":top_langs attribute" do
      it_behaves_like "detected language attribute", :top_langs

      context "when multiple languages are detected" do
        subject { CLD.detect_language_summary('今天是來最偉大的一天。 Time to do some amazing work and kick some asses!  私の友達を始めましょう。')[:top_langs] }

        it 'has internal scores' do
          subject.each{|lang| expect(lang[:score]).to be > 1.0}
        end

        it 'has percents representing the amount of text found in each detected language' do
          subject.each{|lang| expect(lang[:percent]).to be > 25}
        end
      end

      context "when a single language is detected" do
        subject { CLD.detect_language_summary('Hola mi amigo, ¡hoy va a ser épico!')[:top_langs] }

        it 'has internal score' do
          expect(subject[0][:score]).to be > 1.0
        end

        it 'has percent representing the amount of text found in the detected language' do
          expect(subject[0][:percent]).to be > 90
        end
      end
    end

    describe ':chunks atrribute' do
      it_behaves_like "detected language attribute", :chunks

      context "when multiple languages are detected" do
        subject { CLD.detect_language_summary('今天是來最偉大的一天。 Time to do some amazing work and kick some asses!  私の友達を始めましょう。')[:chunks]}

        it 'contains contents of the detected languages in their respective substring chunks' do
          contents = subject.map{|chunk| chunk[:content]}
          expect(contents[0]).to eq '今天是來最偉大的一天。 '
          expect(contents[1]).to eq 'Time to do some amazing work and kick some asses!  '
          expect(contents[2]).to eq '私の友達を始めましょう。'
        end
      end
    end
  end
end