require "sidekiq/monitor"
require "google/cloud/monitoring"

include Sidekiq

class MyLogger
  def initialize
  end

  def info(msg)
    puts msg
  end

end

class Monitoring
    
  def initialize
    @metric_type = "custom.googleapis.com/sidekiq/combined_queue_size"

    @monitoring_client = Google::Cloud::Monitoring.metric_service
    @project_name      = @monitoring_client.project_path project: ENV["PROJECT_ID"]

    if ENV["RECREATE_METRICS"]
      puts "Deleting metric #{@metric_type}"
      @monitoring_client.delete_metric_descriptor(
        name: @monitoring_client.metric_descriptor_path(
          project: ENV["PROJECT_ID"],
          metric_descriptor: @metric_type
        )
      )
    end
    
    @descriptor = Google::Api::MetricDescriptor.new(
      type:        @metric_type,
      metric_kind: Google::Api::MetricDescriptor::MetricKind::GAUGE,
      value_type:  Google::Api::MetricDescriptor::ValueType::INT64,
      description: "This is a simple example of a custom metric."
    )
    
    result = @monitoring_client.create_metric_descriptor(
      name: @project_name,
      metric_descriptor: @descriptor,
    )    
  end

  def write_value value
    series        = Google::Cloud::Monitoring::V3::TimeSeries.new
    series.metric = Google::Api::Metric.new type: @metric_type
    
    resource = Google::Api::MonitoredResource.new type: "global"
    resource.labels["project_id"] = ENV["PROJECT_ID"]
    series.resource = resource
    
    point          = Google::Cloud::Monitoring::V3::Point.new
    point.value    = Google::Cloud::Monitoring::V3::TypedValue.new int64_value: value
    now            = Time.now
    end_time       = Google::Protobuf::Timestamp.new seconds: now.to_i, nanos: now.nsec
    point.interval = Google::Cloud::Monitoring::V3::TimeInterval.new end_time: end_time
    series.points << point
    
    @monitoring_client.create_time_series(
      name: @project_name, 
      time_series: [
        series
      ]
    )
  end
end

class SidekiqMonitoring

  def initialize queues, sleep_interval
    @queues         = queues
    @sleep_interval = sleep_interval
    @logger         = MyLogger.new
    @monitoring     = Monitoring.new
  end

  def sets
    [
      Sidekiq::RetrySet.new,
      Sidekiq::DeadSet.new,
      Sidekiq::ScheduledSet.new,
      Sidekiq::DeadSet.new,
    ]
  end

  def print_monitoring_data
    # Log each queue data
    @queues.each do |q|
      size    = Sidekiq::Queue.new(q).size
      latency = Sidekiq::Queue.new(q).latency

      @logger.info "sdmon_q_size_#{q.to_s}: #{size}"
      @logger.info "sdmon_q_lat_#{q.to_s}: #{latency}"
    end

    # Log predefined sets data
    sets.each do |s|
      size    = s.size
      name    = s.name
      @logger.info "sdmon_q_size_#{name}: #{size}"
    end

    # Log all queues combined data
    @logger.info "sdmon_q_size_all: #{Sidekiq::Stats.new.enqueued}"

    # Log currently processing information data
    busy_count = Sidekiq::ProcessSet.new.map { |x| x["busy"] }.reduce(&:+)
    @logger.info "sdmon_proc_busy: #{busy_count}"

    # Log additional Sidekiq Processes and Workers data
    sdmon_proc_all = Sidekiq::ProcessSet.new.size
    logger.info "sdmon_proc_all: #{sdmon_proc_all}"
    logger.info "sdmon_proc_workers: #{Sidekiq::Workers.new.size}"

    @monitoring.write_value Sidekiq::Stats.new.enqueued

    busy_avg   = (busy_count || 0).to_f / sdmon_proc_all.to_f
    logger.info "sdmon_proc_busy_avg: #{busy_avg}"

    $stdout.flush
  end

  def monitoring_loop count = 180
    count.times do
      print_monitoring_data

      sleep @sleep_interval
      break if @sleep_interval.zero?
    end
  end
end

loop do
  loop_count     = ENV['LOOP_COUNT']&.to_i || 180
  queues         = ENV['SIDEKIQ_MON_QUEUES']&.split(',') || Sidekiq::Queue.all.map(&:name)
  sleep_interval = ENV["SIDEKIQ_MON_SLEEP_INTERVAL_SECS"]&.to_f || 5

  SidekiqMonitoring.new(queues, sleep_interval).monitoring_loop loop_count
end
