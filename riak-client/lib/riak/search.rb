require 'riak'

warn Riak.t('deprecated.search', :backtrace => "    "+caller.join("\n    "))
