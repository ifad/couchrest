require File.expand_path("../../spec_helper", __FILE__)

describe CouchRest::LuceneAPI do
  before(:each) do
    @cr = CouchRest.new(COUCHHOST)
    @db = @cr.database(TESTDB)
    @db.delete! rescue RestClient::ResourceNotFound
    @db = @cr.create_db(TESTDB) # rescue nil
  end

  describe "searching a database" do
    before(:each) do
      search_function = { 'defaults' => {'store' => 'no', 'index' => 'analyzed_no_norms'},
          'index' => "function(doc) { ret = new Document(); ret.add(doc['name'], {'field':'name'}); ret.add(doc['age'], {'field':'age'}); return ret; }" }
      @db.save_doc({'_id' => '_design/search', 'fulltext' => {'people' => search_function}})
      @db.save_doc({'_id' => 'john', 'name' => 'John', 'age' => '31'})
      @db.save_doc({'_id' => 'jack', 'name' => 'Jack', 'age' => '32'})
      @db.save_doc({'_id' => 'dave', 'name' => 'Dave', 'age' => '33'})
    end


    %w( get post ).each do |method|
      it "should work via #{method.upcase}" do
        CouchRest::LuceneAPI.request_method = method.intern

        result = @db.search('search/people', :q => 'name:J*')
        doc_ids = result['rows'].collect{ |row| row['id'] }
        doc_ids.size.should == 2
        doc_ids.should include('john')
        doc_ids.should include('jack')
      end
    end
  end

end if couchdb_lucene_available?
