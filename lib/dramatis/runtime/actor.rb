module Dramatis; end
class Dramatis::Runtime; end

require 'dramatis/runtime/task'
require 'dramatis/runtime/gate'
require 'thread'
require 'pp' #FIX

class Dramatis::Runtime::Actor

  def name
    @name ||= Dramatis::Actor::Name.new self
  end

  attr_reader :object_interface
  attr_reader :gate

  def initialize object = nil
    @object = object
    if object
      @gate = Dramatis::Runtime::Gate.new true
    else
      @gate = Dramatis::Runtime::Gate.new false
    end
    blocked!
    @queue = []
    @mutex = Mutex.new
    @thread = nil
    @continuations = {}
    @object_interface = ObjectInterface.new self
    Dramatis::Runtime::Scheduler.the << self
  end
  
  def deadlock e
    @mutex.synchronize do
      @queue.each do |task|
        task.exception e
      end
      @queue.clear
    end
  end

  def register_continuation c
    # p "selfish", self, @continuations
    # pp "csr", c.to_s
    @continuations[c.to_s] = c
  end

  def bind object
    raise RuntimeError.new( "a snit" ) if @object
    @object = object
    @gate.default = true
    self
  end

  def actor_send args, opts = {}
    common_send :actor, args, opts
  end

  def object_send args, opts = {}
    if opts[:continuation_send]
      type = :continuation 
      begin
        raise "holly hell" if args[0] != :result and args[0] != :exception
      rescue Exception => exception
        pp exception.backtrace
      end
      args.unshift opts[:continuation_send]
    else
      type = :object
    end
    common_send type, args, opts
  end

  def common_send dest, args, opts = {}

    
    # warn "common send #{self} #{dest} #{args.join(' ')} #{opts.to_a.join(' ' )}"

    task = Dramatis::Runtime::Task.new( self, dest, args, opts  )

    @mutex.synchronize do
      # warn "common send r? #{runnable?} g? #{@gate.accepts? task.method} q #{@queue.length}"
      # FIX arguments to gate
      if !runnable? and @gate.accepts? task.method
        runnable!
        Dramatis::Runtime::Scheduler.the.schedule task
      else
        @queue << task
      end
    end

    task.queued

  end

  def deliver dest, args, continuation
    @mutex.synchronize do
      @thread = Thread.current
    end
    begin
      method = args.shift
      # pp "switch", dest.to_s, args
      result = 
        case dest
        when :actor
          # p "send actor #{method}"
          self.send method, *args
          # p "sent actor #{method}"
        when :object
          # p "send object #{method}"
          @object.send method, *args
          # p "sent object #{method}"
        when :continuation
          # p "send continuation #{method}"
          continuation_name = method
          # warn "c is #{continuation_name}"
          c = @continuations[continuation_name]
          # pp "cs", @continuations.keys
          raise "hell 0 #{Thread.current}" if !c
          method = args.shift
          method = case method
                     when :result: :continuation_result
                     when :exception: :continuation_exception
                     else
                       raise "hell *"
                   end
          # pp c.to_s, "send", method, args
          c.send method, *args
          @continuations.delete continuation_name
          # pp "csd", continuation_name, @continuations.keys
        else
          raise "hell 1: " + @dest.to_s
        end
      # p "call c #{result}"
      # p continuation.to_s
      continuation.result result
      # p "called c #{result}"
    rescue Exception => exception
      smp_protect { pp "0 exception ", exception }
      continuation.exception exception
    ensure
      schedule
    end

  end

  # note called from task.rb, too
  def schedule
    @mutex.synchronize do
      @thread = nil
      schedule = nil
      @queue.each_with_index do |task,index|
        # FIX arugments?
        if @gate.accepts? task.method
          schedule = task
          # warn "before: #{@queue}"
          @queue[index,1] = []
          # warn "after: #{@queue}"
        end
      end
      if schedule 
        Dramatis::Runtime::Scheduler.the.schedule schedule
      else
        blocked!
      end
    end
  end

  def blocked!
    # warn "blocked! #{self} #{@state}"
    @state = :blocked
  end

  def runnable!
    # warn "runnable! #{self} #{@state}"
    @state = :runnable
  end

  def runnable?
    # warn "runnable? #{self} #{@state}"
    @state == :runnable
  end

  class ObjectInterface
    def gate
      @actor.gate
    end
    def refuse *args
      @actor.gate.refuse( *args )
    end
    def accept *args
      @actor.gate.accept( *args )
    end
    private
    def initialize actor
      @actor = actor
    end
  end

end

class Object
  def smp_protect
    old = Thread.critical
    Thread.critical = 1
    begin
      yield
    ensure
      Thread.critical = old
    end
  end
end

# Might be nice if this was broken out into another file ... YAGNI?

class Dramatis::Runtime::Actor::Main < Dramatis::Runtime::Actor

  class Object
    class Exception < ::Exception; end
    def method_missing
      raise Exception.new "must use Actor#become to enable main actor"
    end
  end

  def self.the
    @@the ||= self.new
  end

  def self.reset
    @@the = nil
  end

  def finalize
    schedule
    Dramatis::Runtime::Scheduler.the.main_at_exit
  end

  def initialize
    super Object.new
    at_exit { finalize }
  end

end
