module CouchRest

  module LuceneAPI
    class << self
      @@settings = {
        :request_method  => :get,
        :connection_type => :hook,
        :server_name     => 'local'
      }.each do |k,|
        define_method(k) { @@settings[k] }
        define_method("#{k}=") { |v| @@settings[k] = v}
      end
    end

    # Query a CouchDB-Lucene search view
    def search(name, params={})
      send(fti_method, name, params)
    end

    private

    def fti_via_get(name, params)
      MultiJson.decode(CouchRest.get fti_url_for(name, params), :raw => true)
    end

    def fti_via_post(name, params)
      query = params.delete(:q)
      CouchRest.post fti_url_for(name, params), query, :raw => true
    end

    def fti_method
      {:get => :fti_via_get,
       :post => :fti_via_post}.fetch(LuceneAPI.request_method)
    rescue KeyError
      raise ArgumentError, "Invalid lucene query method: #{method}"
    end

    def fti_url_for(view, params)
      @fti_base ||= begin
        path = case (type = LuceneAPI.connection_type)
        when :hook
          [self.name, '_fti/_design']
        when :handler
          ['_fti', LuceneAPI.server_name, self.name, '_design']
        else
          raise ArgumentError, "Invalid lucene connection type: #{type}"
        end

        [@host, path].join('/')
      end

      CouchRest.paramify_url [@fti_base, view].join('/'), params
    end

  end

end
