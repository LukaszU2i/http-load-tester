require 'thread'

module HttpLoadTester
  NUMBER_OF_PROCS = (ENV["PROCS"] || 10).to_i
  NUMBER_OF_REQUESTS = (ENV["REQUESTS"] || 100).to_i

  class Tester
    include MonitorMixin

    class << self
      def run file
        load file
        instance.run
      end

      def instance
        @@tester ||= self.new
      end
    end

    def initialize
      @requests = 0
      @count = 0
      @mutex = Mutex.new
    end

    def scenario_classes
      @scenarios ||= []
    end
    
    def run
      Logger.log "Warming up"

      run_scenarios
      print_summary
    end

    def run_scenarios
      (0...NUMBER_OF_PROCS).collect do
        Thread.new do
          begin
            while true
              scenario_instance = scenario_classes[rand(scenario_classes.length)].new(self)

              scenario_instance.on_start do
                rand(5).times do
                  raise CompletedException.new if @stop_time
                  sleep 1
                end
              end
              
              scenario_instance.on_completion do |uri, response|
                if response.status != 200
                  Logger.log ''
                  Logger.log "#{uri} failed with status #{response.status}"
                end
                show_progress
                increment
              end

              scenario_instance.execute
            end
          rescue CompletedException
          end  
        end
      end.each do |t|
        t.join
      end
    end
    
    def print_summary
      Logger.log ''
      x = @stop_time - @start_time
      Logger.log_summary @count, x
    end
      
    def show_progress
      Logger.log ".", true
    end

    def increment
      @mutex.synchronize do
        if @requests == NUMBER_OF_PROCS
          @start_time = Time.new
          Logger.log ''
          Logger.log "Starting"
        end
        
        if @count == NUMBER_OF_REQUESTS
          @stop_time = Time.new
          Logger.log ''
          Logger.log "Stopping"
        end
      
        if @requests >= NUMBER_OF_PROCS && @count < NUMBER_OF_REQUESTS
          @count += 1
        end
        
        @requests += 1
      end
    end
  end
end

include HttpLoadTester::DSL::Main
