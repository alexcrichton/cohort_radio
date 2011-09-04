class FargoSearch

  @@timers   = {}
  @@sids     = {}
  @@searches = {}
  @client    = nil

  def self.queue; :search end
  def self.client= client; @@client = client end

  def self.perform data
    query   = data['query']
    channel = data['channel']
    search  = Fargo::Search.new :query => query
    @@searches[channel] = search

    if @@timers.key?(channel)
      @@timers[channel].cancel # Cancel the timer, we'll re-add it
    else
      # If we get a matching search result, notify over pusher
      raise 'Should not be here' if @@sids.key?(channel)
      @@sids[channel] = @@client.channel.subscribe do |type, message|
        next if type != :search_result || !@@searches[channel].matches?(message)
        Pusher[channel].trigger_async('search-result', message)
      end
    end

    # Unsubscribe after a minute
    @@timers[channel] = EM::Timer.new(60) {
      @@client.channel.unsubscribe @@sids[channel]
      @@timers.delete channel
      @@sids.delete channel
      @@searches.delete channel
    }

    @@client.search search
  end

end
