require "sidekiq/monitor"

include Sidekiq

def sets
  [
    Sidekiq::RetrySet.new,
    Sidekiq::DeadSet.new,
    Sidekiq::ScheduledSet.new,
    Sidekiq::DeadSet.new,
  ]
end

def queues
  [
    :hipri,
    :default,
    :lowpri,
    :mailer,
    :crawler,
  ]
end

class MyLogger
  def initialize
  end

  def info(msg)
    puts msg
  end
end

def logger
  MyLogger.new
end

def print_monitoring_data
  queues.each do |q|
    size = Sidekiq::Queue.new(q).size
    logger.info "sdmon_q_size_#{q.to_s}: #{size}"
  end

  sets.each do |s|
    size = s.size
    name = s.name
    logger.info "sdmon_q_size_#{name}: #{size}"
  end

  logger.info "sdmon_q_size_all: #{Sidekiq::Stats.new.enqueued}"

  busy_count = Sidekiq::ProcessSet.new.map { |x| x["busy"] }.reduce(&:+)
  logger.info "sdmon_proc_busy: #{busy_count}"

  logger.info "sdmon_proc_all: #{Sidekiq::ProcessSet.new.size}"
  logger.info "sdmon_proc_workers: #{Sidekiq::Workers.new.size}"
  $stdout.flush
end

def monitoring_loop
  sleep_time = ENV["SIDEKIQ_MON_SLEEP_INTERVAL"]&.to_i || 5

  loop do
    print_monitoring_data

    sleep sleep_time
    break if sleep_time.zero?
  end
end

monitoring_loop
