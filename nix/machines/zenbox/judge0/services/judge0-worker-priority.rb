# Resque owns job reservation. Standby workers finish current jobs but do not
# reserve another while the primary has a recent heartbeat in shared Redis.
Resque.heartbeat_interval = 5

if ENV['JUDGE0_PRIMARY_WORKER_HOST']
  module Judge0Standby
    def reserve
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      if !@primary_checked_at || now - @primary_checked_at >= 2
        redis_now = Resque.redis.time.first.to_i
        prefix = ENV.fetch('JUDGE0_PRIMARY_WORKER_HOST') + ':'
        @primary_alive = Resque::Worker.all_heartbeats.any? do |id, heartbeat|
          id.start_with?(prefix) && heartbeat &&
            redis_now - Time.parse(heartbeat).to_i < 15
        end
        @primary_checked_at = now
      end
      super unless @primary_alive
    end
  end
  Resque::Worker.prepend(Judge0Standby)
end
