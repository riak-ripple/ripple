# `ripple`: Riak Document Models [![Build Status](https://secure.travis-ci.org/basho/ripple.png)](http://travis-ci.org/basho/ripple)

`ripple` is a rich Ruby modeling layer for Riak, Basho's distributed
database that contains an ActiveModel-based document abstraction which
is inspired by ActiveRecord, DataMapper, and MongoMapper.

## Dependencies

`ripple` requires Ruby 1.8.7 or later and versions 3 or above of
ActiveModel and ActiveSupport (and their dependencies, including
i18n). Naturally, it also depends on the `riak-client` gem to connect
to Riak.

Development dependencies are handled with bundler. Install bundler
(`gem install bundler`) and run this command in each sub-project to
get started:

``` bash
$ bundle install
```

Run the RSpec suite using `bundle exec`:

``` bash
$ bundle exec rake spec
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
  host: 127.0.0.1

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
  host: 127.0.0.1
  bin_dir: /usr/local/bin   # Default for Homebrew.
  js_source_dir: <%%= Rails.root + "app/mapreduce" %>

production:
  http_port: 8098
  pb_port: 8087
  host: 127.0.0.1
```

`require 'ripple/railtie'` from your `config/application.rb` file to complete the integration.


## How to Contribute

* Fork the project on [Github](http://github.com/basho/ripple).  If you have already forked, use `git pull --rebase` to reapply your changes on top of the mainline. Example:

    ``` bash
    $ git checkout master
    $ git pull --rebase basho master
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
* Commit, do not mess with Rakefile or VERSION.  If related to an existing issue in the [tracker](http://github.com/basho/ripple/issues), include "Closes #X" in the commit message (where X is the issue number).
* Send me a pull request.

## License & Copyright

Copyright &copy;2010-2012 Sean Cribbs and Basho Technologies, Inc.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
