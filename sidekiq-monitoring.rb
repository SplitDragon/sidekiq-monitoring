require "sidekiq/logger"
require "sidekiq/client"
require "sidekiq/worker"
require "sidekiq/redis_connection"
require "sidekiq/delay"
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

def monitoring_loop
  queues.each do |q|
    size = Sidekiq::Queue.new(q).size
    logger.info "sidekiq_metrics_queue_size_#{q.to_s}: #{size}"
  end

  sets.each do |s|
    size = s.size
    name = s.name
    logger.info "sidekiq_metrics_queue_size_#{name}: #{size}"
  end

  logger.info "sidekiq_metrics_all_queues_size: #{Sidekiq::Stats.new.enqueued}"

  busy_count = Sidekiq::ProcessSet.new.map { |x| x["busy"] }.reduce(&:+)
  logger.info "sidekiq_metrics_busy_count: #{busy_count}"

  logger.info "sidekiq_metrics_worker_count: #{Sidekiq::Workers.new.size}"
end

monitoring_loop
