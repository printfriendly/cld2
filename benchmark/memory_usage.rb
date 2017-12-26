require 'cld'

def memory_usage
  str = "anni dall'Unità d'Italia : rileggere il Risorgimento tra storia e cultura. hello this is the greatest day ever love and peace, 今天是有史以來最偉大的一天"
  100.times do |t|
    100000.times { |i|
      CLD.detect_language_summary(str)
      CLD.detect_summary(str)
      CLD.detect(str)
      CLD.detect_language(str)
    }
    mem = `ps -o rss -p #{Process.pid}`[/\d+/]
    puts "Current memory #{t}:  #{mem}"
    GC.start
  end
end

memory_usage