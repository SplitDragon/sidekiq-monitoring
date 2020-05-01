require "sidekiq/monitor"
include Sidekiq

class MyLogger
  def initialize
  end

  def info(msg)
    puts msg
  end
end

class SidekiqMonitoring

  def initialize queues, sleep_interval
    @queues         = queues
    @sleep_interval = sleep_interval
  end

  def sets
    [
      Sidekiq::RetrySet.new,
      Sidekiq::DeadSet.new,
      Sidekiq::ScheduledSet.new,
      Sidekiq::DeadSet.new,
    ]
  end

  def logger
    MyLogger.new
  end

  def print_monitoring_data
    # Log each queue data
    @queues.each do |q|
      size    = Sidekiq::Queue.new(q).size
      latency = Sidekiq::Queue.new(q).latency

      logger.info "sdmon_q_size_#{q.to_s}: #{size}"
      logger.info "sdmon_q_lat_#{q.to_s}: #{latency}"
    end

    # Log predefined sets data
    sets.each do |s|
      size    = s.size
      name    = s.name
      logger.info "sdmon_q_size_#{name}: #{size}"
    end

    # Log all queues combined data
    logger.info "sdmon_q_size_all: #{Sidekiq::Stats.new.enqueued}"

    # Log currently processing information data
    busy_count = Sidekiq::ProcessSet.new.map { |x| x["busy"] }.reduce(&:+)
    logger.info "sdmon_proc_busy: #{busy_count}"

    # Log additional Sidekiq Processes and Workers data
    logger.info "sdmon_proc_all: #{Sidekiq::ProcessSet.new.size}"
    logger.info "sdmon_proc_workers: #{Sidekiq::Workers.new.size}"
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
