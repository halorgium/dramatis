module Dramatis; end
module Dramatis::Actor; end

require 'dramatis/runtime/name_server'
require 'dramatis/runtime/actor/name/proxy'

module Dramatis::Actor

  Runtime = Dramatis::Runtime
  NameServer = Runtime::NameServer
  Proxy = Runtime::Actor::Name::Proxy

  def self.Name *args, &block
    Proxy.new *args, &block
  end

  def self.acts_as klass

    klass.class_eval do
      def actor
        @__dramatis__ ||= Dramatis::Runtime::NameServer.the[self]
      end
    end

  end

end
