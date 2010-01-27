module HttpLoadTester
  class Logger

    def self.log message, oneline = false
      return if ENV['CSV'] == 'true'
      
      if oneline
        STDOUT.print message
        STDOUT.flush
        return
      end

      puts message
    end
    
    def self.log_summary no_of_requests, connection_time
      if ENV['CSV'] == 'true'
        puts "#{NUMBER_OF_PROCS}, #{NUMBER_OF_REQUESTS}, #{no_of_requests}, #{connection_time}"
        return
      end

      puts "#{no_of_requests} request in #{connection_time} seconds"
      puts "#{no_of_requests/connection_time} requests per second"
    end
    
  end
end
