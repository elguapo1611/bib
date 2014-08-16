require "csv"
require "neography"

# setup neography
Neography.configure do |config|
  config.protocol             = "http://"
  config.server               = "localhost"
  config.port                 = 7474
  config.directory            = ""  # prefix this path with '/'
  config.cypher_path          = "/cypher"
  config.gremlin_path         = "/ext/GremlinPlugin/graphdb/execute_script"
  config.log_file             = "neography.log"
  config.log_enabled          = false
  config.slow_log_threshold   = 0    # time in ms for query logging
  config.max_threads          = 20
  config.authentication       = nil  # 'basic' or 'digest'
  config.username             = nil
  config.password             = nil
  config.parser               = MultiJsonParser
  config.http_send_timeout    = 4200
  config.http_receive_timeout = 4200
end


class Bibliography

  INDEX_NAME = "bib"
  KEYWORD_KEY = "keyword"

  attr_accessor :id,
                :authors,
                :title,
                :year,
                :source,
                :volume,
                :issue,
                :art_no,
                :page_start,
                :page_end,
                :page_count,
                :cited_by,
                :link,
                :abstract,
                :author_keywords,
                :index_keywords,
                :document_type,
                :source

  def initialize(row)
    @id               = row["ID"]
    @authors          = row["X.Authors"].split(",")
    @title            = row["Title"]
    @year             = row["Year"]
    @source           = row["Source.title"]
    @volume           = row["Volume"]
    @issue            = row["Issue"]
    @art_no           = row["Art..No."]
    @page_start       = row["Page.start"]
    @page_end         = row["Page.end"]
    @page_count       = row["Page.count"]
    @cited_by         = row["Cited.by"]
    @link             = row["Link"]
    @abstract         = row["Abstract"]
    @author_keywords  = row["Author.Keywords"] ? row["Author.Keywords"].split(/,|;/) : []
    @index_keywords   = row["Index.Keywords"] ? row["Index.Keywords"].split(/,|;/) : []
    @document_type    = row["Document.Type"]
    @source           = row["Source"]
  end

  def neo
    @@neo ||= Neography::Rest.new
  end

  def neo_index_all
    neo_index_year
    neo_index_keywords
    neo_index_publication
  end

  def neo_index_publication
    node = neo.create_unique_node(INDEX_NAME, "publication", id, publication_as_node)
    neo.add_label(node, "publication")
    neo.add_label(node, document_type)
  rescue
    puts "whoooops #{id}"
  end

  def publication_as_node
    {
      "title" => title,
      "source" => source,
      "volume" => volume,
      "issue" => issue,
      "art_no" => art_no,
      "page_start" => page_start,
      "page_end" => page_end,
      "page_count" => page_count,
      "link" => link,
      "abstract" => abstract,
      "document_type" => document_type,
      "source" => source
    }
  end

  def neo_index_year
    node = neo.create_unique_node(INDEX_NAME, "date", year, {"year" => year})
    neo.add_label(node, "year")
  end

  def neo_index_keywords
    (author_keywords + index_keywords).map do |keyword|
      node = neo.create_unique_node(INDEX_NAME, KEYWORD_KEY, keyword, {"name" => keyword})
      neo.add_label(node, KEYWORD_KEY) 
    end
  end

end

csv_options = {:headers => true,  :encoding => 'ISO8859-1'}
CSV.foreach('./db/articles.csv', csv_options) do |csv_obj|
  Bibliography.new(csv_obj).neo_index_all
end

