require 'net/telnet'
require 'singleton'

require 'scalarm/service_core'
require 'scalarm/database/core'
require 'scalarm/database/model/experiment'
#172.16.67.206, 27017
##scalarm_db


class TelentConnection

  attr_accessor :ip, :port

  def initialize(ip,port)
    @con = nil
    @ip = ip
    @port = port
    openConnection
  end

  def openConnection
    @con = Net::Telnet::new("Host" => ip,
                            "Port" => port,
                            "Telnetmode" => false,
                            "Timeout" =>10,
                            "Prompt" => /[$%#>] \z/n)
  end

  def connect_to_scalarm_db
    Scalarm::Database::MongoActiveRecord.connection_init('149.156.10.32:56453','scalarm_db')
  end

  def run
    @thread = Thread.new do
      while(true)
        self.writeMetrics
        sleep(5)
      end
    end
    @thread.join()

  end

  def get_all_simulations
    #all simulations
    query = lambda {
      (Scalarm::Database::Model::Experiment.map do |e|
        e.size
      end).reduce(:+)
    }
    return query_scalarm(query)
  end

  def get_information_service_response_time
    #all simulations already completed
    query = lambda {
      (Scalarm::Database::Model::Experiment.map do |e|
        e.simulation_runs.where(is_done: true).count
      end).reduce(:+)
    }
    return query_scalarm(query)
  end

  def get_completed_simulations
    #all simulations already completed
    query = lambda {
      (Scalarm::Database::Model::Experiment.map do |e|
        e.simulation_runs.where(is_done: true).count
      end).reduce(:+)
    }
    return query_scalarm(query)
  end

  def query_scalarm(query)
    begin
      return query.call
    rescue
      self.connect_to_scalarm_db
      return query.call
    end
  end

  def writeMetrics
  puts "writing metrics"
    throughput = (self.get_completed_simulations/self.get_all_simulations).to_i
    writeMetric('Scalarm','SystemSimulationsThroughput',3600,throughput)
    writeMetric('Scalarm','ResponseTimeOfOneExperimentManagerMetric',3600,throughput)
    writeMetric('Scalarm','InformationServiceResponseTime',3600,throughput)

  end

  def writeMetric(app_name,metric_name,time,value)
    puts "#{app_name} #{metric_name} #{value} #{time}"
    @con.write("#{app_name} #{metric_name} #{value} #{time}\n")
    #@con.close
  end


end

ip='127.0.0.1'
port=27182

t = TelentConnection.new(ip,port)
t.run