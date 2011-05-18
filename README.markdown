# ripple

ripple is a rich Ruby toolkit for Riak, Basho's distributed database. It consists of three gems:

* `riak-client` (`Riak` namespace) contains a basic wrapper around typical operations, including bucket manipulation, object CRUD, link-walking, and map-reduce.
* `ripple` (`Ripple` namespace) contains an ActiveModel-compatible modeling layer that is inspired by ActiveRecord, DataMapper, and MongoMapper.
* `riak-sessions` contains session stores for Rack and Rails 3 applications.

## Dependencies

`riak-client` requires i18n and either json or yajl-ruby. For higher performance on HTTP requests, install the 'curb' or 'excon' gems. The cache store implementation requires ActiveSupport 3 or later.

`ripple` requires Ruby 1.8.7 or later and versions 3 or above of ActiveModel and ActiveSupport (and their dependencies, including i18n).

`riak-sessions` requires Rack (any version > 1.0), and Rails 3.0 if you want the Rails-specific session store.

Development dependencies are handled with bundler. Install bundler (`gem install bundler`) and run this command in each sub-project to get started:

``` bash
$ bundle install
```

Run the RSpec suite using `bundle exec`:

``` bash
$ bundle exec rake spec
```

## Basic Example

``` ruby
require 'riak'

# Create a client interface
client = Riak::Client.new

# Create a client interface that uses Excon
client = Riak::Client.new(:http_backend => :Excon)

# Create a client that uses Protocol Buffers
client = Riak::Client.new(:protocol => "pbc")

# Retrieve a bucket
bucket = client.bucket("doc")  # a Riak::Bucket

# Get an object from the bucket
object = bucket.get("index.html")   # a Riak::RObject

# Change the object's data and save
object.data = "<html><body>Hello, world!</body></html>"
object.store

# Reload an object you already have
object.reload                  # Works if you have the key and vclock, using conditional GET
object.reload :force => true   # Reloads whether you have the vclock or not

# Access more like a hash, client[bucket][key]
client['doc']['index.html']   # the Riak::RObject

# Create a new object
new_one = Riak::RObject.new(bucket, "application.js")
new_one.content_type = "application/javascript" # You must set the content type.
new_one.data = "alert('Hello, World!')"
new_one.store
```

## Map-Reduce Example

``` ruby
# Assuming you've already instantiated a client, get the album titles for The Beatles
results = Riak::MapReduce.new(client).
                add("artists","Beatles").
                link(:bucket => "albums").
                map("function(v){ return [JSON.parse(v.values[0].data).title]; }", :keep => true).run

p results # => ["Please Please Me", "With The Beatles", "A Hard Day's Night", 
          #     "Beatles For Sale", "Help!", "Rubber Soul",
          #     "Revolver", "Sgt. Pepper's Lonely Hearts Club Band", "Magical Mystery Tour", 
          #     "The Beatles", "Yellow Submarine", "Abbey Road", "Let It Be"]
```


## Riak Search Examples

For more information about Riak Search, see [the Basho wiki](http://wiki.basho.com/display/RIAK/Riak+Search).

``` ruby
require 'riak/search' # optional riak_search additions

# Create a client, specifying the Solr-compatible endpoint
client = Riak::Client.new :solr => "/solr"

# Search the default index for documents
result = client.search("title:Yesterday") # Returns a vivified JSON object
                                          # containing 'responseHeaders' and 'response' keys
result['response']['numFound'] # total number of results
result['response']['start']    # offset into the total result set
result['response']['docs']     # the list of indexed documents

# Search the 'users' index for documents
client.search("users", "name:Sean")

# Add a document to an index
client.index("users", {:id => "sean@basho.com", :name => "Sean Cribbs"}) # adds to the 'users' index

client.index({:id => "index.html", :content => "Hello, world!"}) # adds to the default index

client.index({:id => 1, :name => "one"}, {:id => 2, :name => "two"}) # adds multiple docs

# Remove document(s) from an index
client.remove({:id => 1})             # removes the document with ID 1
client.remove({:query => "archived"}) # removes all documents matching query
client.remove({:id => 1}, {:id => 5}) # removes multiple docs

client.remove("users", {:id => "sean@basho.com"}) # removes from the 'users' index

# Seed MapReduce with search results
Riak::MapReduce.new(client).
        search("users","email:basho").
        map("Riak.mapValuesJson", :keep => true).
        run

# Detect whether a bucket has auto-indexing
client['users'].is_indexed?

# Enable auto-indexing on a bucket
client['users'].enable_index!

# Disable auto-indexing on a bucket
client['users'].disable_index!
```

## Document Model Examples

``` ruby
require 'ripple'

# Documents are stored as JSON objects in Riak but have rich
# semantics, including validations and associations.
class Email
  include Ripple::Document
  property :from,    String, :presence => true
  property :to,      String, :presence => true
  property :sent,    Time,   :default => proc { Time.now }
  property :body,    String
end

email = Email.find("37458abc752f8413e")  # GET /riak/emails/37458abc752f8413e
email.from = "someone@nowhere.net"
email.save                               # PUT /riak/emails/37458abc752f8413e

reply = Email.new
reply.from = "justin@bashoooo.com"
reply.to   = "sean@geeemail.com"
reply.body = "Riak is a good fit for scalable Ruby apps."
reply.save                               # POST /riak/emails (Riak-assigned key)

# Documents can contain embedded documents, and link to other standalone documents 
# via associations using the many and one class methods.
class Person
  include Ripple::Document
  property :name, String
  many :addresses
  many :friends, :class_name => "Person"
  one :account
end

# Account and Address are embeddable documents
class Account
  include Ripple::EmbeddedDocument
  property :paid_until, Time
  embedded_in :person # Adds "person" method to get parent document
end

class Address
  include Ripple::EmbeddedDocument
  property :street, String
  property :city, String
  property :state, String
  property :zip, String
end

person = Person.find("adamhunter")
person.friends << Person.find("seancribbs") # Links to people/seancribbs with tag "friend"
person.addresses << Address.new(:street => "100 Main Street") # Adds an embedded address
person.account.paid_until = 3.months.from_now
```


## Configuration Example

When using Ripple with Rails 3, add ripple to your Gemfile and then run the `ripple` generator.  This will generate a test harness, some MapReduce functions and a configuration file. Example:

```
$ rails g ripple
      create  config/ripple.yml
      create  app/mapreduce
      create  app/mapreduce/contrib.js
      create  app/mapreduce/ripple.js
      create  test/ripple_test_helper.rb
      insert  test/test_helper.rb
      insert  test/test_helper.rb
```

`config/ripple.yml` should contain your Riak connection information, and settings for the test server. Example:

``` yaml
# Configure Riak connections for the Ripple library.
development:
  http_port: 8098
  pb_port: 8087
  host: localhost

# The test environment has additional keys for configuring the
# Riak::TestServer for your test/spec suite:
#
# * bin_dir specifies the path to the "riak" script that you use to
#           start Riak (just the directory)
# * js_source_dir specifies where your custom Javascript functions for
#           MapReduce should be loaded from. Usually app/mapreduce.
test:
  http_port: 9000
  pb_port: 9002
  host: localhost
  bin_dir: /usr/local/bin   # Default for Homebrew.
  js_source_dir: <%%= Rails.root + "app/mapreduce" %>

production:
  http_port: 8098
  pb_port: 8087
  host: localhost
```

`require 'ripple/railtie'` from your `config/application.rb` file to complete the integration.


## How to Contribute

* Fork the project on [Github](http://github.com/seancribbs/ripple).  If you have already forked, use `git pull --rebase` to reapply your changes on top of the mainline. Example:

    ``` bash
    $ git checkout master
    $ git pull --rebase seancribbs master
    ```
* Create a topic branch. If you've already created a topic branch, rebase it on top of changes from the mainline "master" branch. Examples:
  * New branch:

        ``` bash
        $ git checkout -b topic
        ```
  * Existing branch:

        ``` bash
        $ git rebase master
        ```
* Write an RSpec example or set of examples that demonstrate the necessity and validity of your changes. **Patches without specs will most often be ignored. Just do it, you'll thank me later.** Documentation patches need no specs, of course.
* Make your feature addition or bug fix. Make your specs and stories pass (green).
* Run the suite using multiruby or rvm to ensure cross-version compatibility.
* Cleanup any trailing whitespace in your code (try @whitespace-mode@ in Emacs, or "Remove Trailing Spaces in Document" in the "Text" bundle in Textmate).
* Commit, do not mess with Rakefile or VERSION.  If related to an existing issue in the [tracker](http://github.com/seancribbs/ripple/issues), include "Closes #X" in the commit message (where X is the issue number).
* Send me a pull request.

## License & Copyright

Copyright &copy;2010 Sean Cribbs, Sonian Inc., and Basho Technologies, Inc.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

## Auxillary Licenses

The included photo (spec/fixtures/cat.jpg) is Copyright &copy;2009 [Sean Cribbs](http://seancribbs.com/), and is licensed under the [Creative Commons Attribution Non-Commercial 3.0](http://creativecommons.org/licenses/by-nc/3.0) license. 
!["Creative Commons"](http://i.creativecommons.org/l/by-nc/3.0/88x31.png)

The "Poor Man's Fibers" implementation (lib/riak/util/fiber1.8.rb) is Copyright &copy;2008 Aman Gupta.
