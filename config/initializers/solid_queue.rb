Rails.application.configure do
  config.solid_queue.concurrency = ENV.fetch("SOLID_QUEUE_CONCURRENCY", 5).to_i
  config.solid_queue.polling_interval = ENV.fetch("SOLID_QUEUE_POLLING_INTERVAL", 0.1).to_f
end
