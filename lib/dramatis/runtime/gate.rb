module Dramatis; end
class Dramatis::Runtime; end

class Dramatis::Runtime::Gate

  def self.new *args
    Hash.new( *args )
  end

  class Base

    def initialize default
      @default = default
    end

    def accepts? arg
      @default
    end

    def default= value
      old = @default
      @default = value
      old
    end

  end

  class Hash < Base

    def initialize default
      super default
      @hash = {}
    end

    def refuse method
      warn "refuse #{method}"
      @hash[ method ] = false
    end

    def accept method
      warn "accept #{method}"
      @hash[ method ] = true
    end

    def default method
      @hash.delete method
    end

    def accepts? method
      v = @hash.has_key?( method ) ? @hash[method] : super( method )
      warn "accepts? #{method} => #{v}"
      v
    end

  end

end