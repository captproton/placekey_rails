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
      expect(elapsed_time).to be < 0.2 # Should be very quick but allow more time for CI environments
    end

    it "enforces waiting when limit is reached" do
      # Allow stubbing of sleep for testing
      allow_any_instance_of(Kernel).to receive(:sleep) { |_, duration| duration }

      # Record all calls to sleep
      sleep_durations = []
      allow(limiter).to receive(:sleep) { |duration| sleep_durations << duration }

      # First use up the limit
      limit.times do
        limiter.wait!
      end

      # The next call should try to wait
      limiter.wait!

      # We should have attempted to sleep at least once
      expect(sleep_durations).not_to be_empty
      expect(sleep_durations.first).to be > 0
    end

    it "cleans up old timestamps" do
      # Mock Time.now to return incrementing values
      times = [
        Time.now,
        Time.now + 0.1,
        Time.now + 0.2,
        Time.now + (period + 0.1) # This is after the expiration period
      ]

      allow(Time).to receive(:now).and_return(*times)

      # Use up the limit
      limit.times do
        limiter.wait!
      end

      # Should now allow a request without waiting (all previous timestamps expired)
      expect(limiter).not_to receive(:sleep)
      limiter.wait!
    end
  end
end
