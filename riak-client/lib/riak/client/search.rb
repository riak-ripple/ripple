require 'builder'

module Riak
  class Client
    # (Riak Search) Performs a search via the Solr interface.
    # @overload search(index, query, options={})
    #   @param [String] index the index to query on
    #   @param [String] query a Lucene query string
    # @overload search(query, options={})
    #   Queries the default index
    #   @param [String] query a Lucene query string
    # @param [Hash] options extra options for the Solr query
    # @option options [String] :df the default field to search in
    # @option options [String] :'q.op' the default operator between terms ("or", "and")
    # @option options [String] :wt ("json") the response type - "json" and "xml" are valid
    # @option options [String] :sort ('none') the field and direction to sort, e.g. "name asc"
    # @option options [Fixnum] :start (0) the offset into the query to start from, e.g. for pagination
    # @option options [Fixnum] :rows (10) the number of results to return
    # @return [Hash] the query result, containing the 'responseHeaders' and 'response' keys
    def search(*args)
      options = args.extract_options!
      index, query = args[-2], args[-1]  # Allows nil index, while keeping it as firstargument
      http do |h|
        h.search(index, query, options)
      end
    end
    alias :select :search

    # (Riak Search) Adds documents to a search index via the Solr interface.
    # @overload index(index, *docs)
    #   Adds documents to the specified search index
    #   @param [String] index the index in which to add/update the given documents
    #   @param [Array<Hash>] docs unnested document hashes, with one key per field
    # @overload index(*docs)
    #   Adds documents to the default search index
    #   @param [Array<Hash>] docs unnested document hashes, with one key per field
    # @raise [ArgumentError] if any documents don't include 'id' key
    def index(*args)
      index = args.shift if String === args.first # Documents must be hashes of fields
      raise ArgumentError.new(t("search_docs_require_id")) unless args.all? {|d| d.key?("id") || d.key?(:id) }
      xml = Builder::XmlMarkup.new
      xml.add do
        args.each do |doc|
          xml.doc do
            doc.each do |k,v|
              xml.field('name' => k.to_s) { xml.text!(v.to_s) }
            end
          end
        end
      end
      http do |h|
        h.update_search_index(index, xml.target!)
      end
      true
    end
    alias :add_doc :index

    # (Riak Search) Removes documents from a search index via the Solr interface.
    # @overload remove(index, specs)
    #   Removes documents from the specified index
    #   @param [String] index the index from which to remove documents
    #   @param [Array<Hash>] specs the specificaiton of documents to remove (must contain 'id' or 'query' keys)
    # @overload remove(specs)
    #   Removes documents from the default index
    #   @param [Array<Hash>] specs the specification of documents to remove (must contain 'id' or 'query' keys)
    # @raise [ArgumentError] if any document specs don't include 'id' or 'query' keys
    def remove(*args)
      index = args.shift if String === args.first
      raise ArgumentError.new(t("search_remove_requires_id_or_query")) unless args.all? { |s|
        s.include? :id or
        s.include? 'id' or
        s.include? :query or
        s.include? 'query'
      }
      xml = Builder::XmlMarkup.new
      xml.delete do
        args.each do |spec|
          spec.each do |k,v|
            xml.tag!(k.to_sym, v)
          end
        end
      end
      http do |h|
        h.update_search_index(index, xml.target!)
      end
      true
    end
    alias :delete_doc :remove
    alias :deindex :remove
  end
end
