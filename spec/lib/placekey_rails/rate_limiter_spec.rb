require 'rails_helper'

RSpec.describe PlacekeyRails::RateLimiter do
  let(:limit) { 3 }
  let(:period) { 0.5 } # Half a second for faster tests
  let(:limiter) { described_class.new(limit: limit, period: period) }

  describe "#wait!" do
    it "allows requests up to the limit without waiting" do
      start_time = Time.now
      
      limit.times do
        limiter.wait!
      end
      
      elapsed_time = Time.now - start_time
      expect(elapsed_time).to be < 0.1 # Should be very quick
    end
    
    it "enforces waiting when limit is reached" do
      # First use up the limit
      limit.times do
        limiter.wait!
      end
      
      # The next call should wait for approximately 'period' seconds
      start_time = Time.now
      limiter.wait!
      elapsed_time = Time.now - start_time
      
      # Allow for some timing variation in test environments
      expect(elapsed_time).to be >= (period * 0.8)
    end
    
    it "cleans up old timestamps" do
      # Use up the limit
      limit.times do
        limiter.wait!
      end
      
      # Wait for the period to expire
      sleep period + 0.1
      
      # Should now allow requests without waiting
      start_time = Time.now
      limiter.wait!
      elapsed_time = Time.now - start_time
      
      expect(elapsed_time).to be < 0.1 # Should be very quick
    end
  end
end
