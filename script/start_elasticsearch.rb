java_64 = ` java -version 2>&1 | grep "64-Bit" -  `
 
elastic_search_defined = `which elasticsearch`
 
if elastic_search_defined.empty?
  raise "could not find elasticsearch in your environment. Please install elasticsearch via `brew update; brew install elasticsearch` "  
else
 
  elastic_search_version = `elasticsearch -v`
  raise "you don't have the correct version of elasticsearch installed.  This app requires elasticsearch 1.3.x." unless elastic_search_version.index(/1.3.[\d]/)
  File.open("log/development.log", "a+") do |f| 
    if f.size > 1000000
      puts "truncating the log file #{f.size.inspect}"
      f.truncate(0)
    end
  end
  `JAVA_OPTS="-Xmx2g -Xms2g"; elasticsearch -Des.config=config/elasticsearch.yml -Xms1024m -Xmx2048m ` 
end
