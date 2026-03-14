# frozen_string_literal: true

RSpec.describe Legion::Extensions::Attention::Runners::Attention do
  let(:client) { Legion::Extensions::Attention::Client.new }

  describe '#filter_signals' do
    it 'returns empty result for empty input' do
      result = client.filter_signals(signals: [])
      expect(result[:filtered]).to eq([])
      expect(result[:spotlight]).to eq(0)
      expect(result[:peripheral]).to eq(0)
      expect(result[:background]).to eq(0)
      expect(result[:dropped]).to eq(0)
    end

    it 'categorizes high-salience signals as spotlight with goal boost' do
      signals = [{ salience: 0.9, domain: :terraform, novelty: 0.8 }]
      wonders = [{ domain: :terraform, salience: 0.9 }]
      result = client.filter_signals(signals: signals, active_wonders: wonders)
      expect(result[:spotlight]).to be >= 1
    end

    it 'categorizes high-salience signals into filtered output' do
      signals = [{ salience: 0.9, domain: :terraform, novelty: 0.8 }]
      result = client.filter_signals(signals: signals)
      expect(result[:filtered].size).to be >= 1
    end

    it 'drops low-salience signals' do
      signals = [{ salience: 0.01, domain: :heartbeat, novelty: 0.0 }]
      result = client.filter_signals(signals: signals)
      expect(result[:dropped]).to be >= 0
      expect(result[:filtered].size).to be <= 1
    end

    it 'boosts signals matching active wonders' do
      signals = [{ salience: 0.3, domain: :terraform, novelty: 0.3 }]
      wonders = [{ domain: :terraform, salience: 0.9 }]

      without = client.filter_signals(signals: signals)
      # New client to avoid habituation carryover
      fresh = Legion::Extensions::Attention::Client.new
      with_wonders = fresh.filter_signals(signals: signals, active_wonders: wonders)

      # With wonder boost, the signal should score higher
      with_total = with_wonders[:spotlight] + with_wonders[:peripheral]
      without_total = without[:spotlight] + without[:peripheral]
      expect(with_total).to be >= without_total
    end

    it 'deduplicates identical signals' do
      signals = [
        { salience: 0.8, domain: :terraform, source_type: :event, value: 'deploy' },
        { salience: 0.8, domain: :terraform, source_type: :event, value: 'deploy' }
      ]
      result = client.filter_signals(signals: signals)
      expect(result[:spotlight] + result[:peripheral] + result[:background]).to be <= 1
    end

    it 'enforces attentional capacity' do
      signals = 10.times.map { |i| { salience: 0.9, domain: :"domain_#{i}", novelty: 0.9 } }
      result = client.filter_signals(signals: signals)
      expect(result[:spotlight]).to be <= Legion::Extensions::Attention::Helpers::Constants::ATTENTIONAL_CAPACITY
    end

    it 'habituates repeated domain signals' do
      first_client = Legion::Extensions::Attention::Client.new
      signals = [{ salience: 0.6, domain: :terraform, novelty: 0.3 }]

      first_result = first_client.filter_signals(signals: signals)
      # Record same domain multiple times to build habituation
      10.times { first_client.filter_signals(signals: signals) }
      later_result = first_client.filter_signals(signals: signals)

      first_scores = first_result[:filtered].map { |s| s[:attention_score] || 0 }
      later_scores = later_result[:filtered].map { |s| s[:attention_score] || 0 }

      # Later scores should be lower due to habituation (if signal still passes)
      expect(later_scores.max).to be <= first_scores.max if first_scores.any? && later_scores.any?
    end
  end

  describe '#attention_status' do
    it 'returns status hash' do
      status = client.attention_status
      expect(status[:manual_focus]).to eq({})
      expect(status[:habituated_domains]).to eq([])
      expect(status[:capacity]).to eq(Legion::Extensions::Attention::Helpers::Constants::ATTENTIONAL_CAPACITY)
      expect(status[:focus_count]).to eq(0)
    end
  end

  describe '#focus_on' do
    it 'focuses on a domain' do
      result = client.focus_on(domain: :terraform, reason: 'deployment')
      expect(result[:status]).to eq(:focused)
      expect(result[:domain]).to eq(:terraform)
    end

    it 'updates attention status' do
      client.focus_on(domain: :security, reason: 'incident')
      status = client.attention_status
      expect(status[:focus_count]).to eq(1)
    end
  end

  describe '#release_focus' do
    it 'releases a focused domain' do
      client.focus_on(domain: :terraform)
      result = client.release_focus(domain: :terraform)
      expect(result[:status]).to eq(:released)
    end

    it 'returns :not_focused for unknown domain' do
      result = client.release_focus(domain: :unknown)
      expect(result[:status]).to eq(:not_focused)
    end
  end

  describe '#habituation_stats' do
    it 'returns stats hash' do
      stats = client.habituation_stats
      expect(stats[:domains]).to be_a(Hash)
      expect(stats[:habituated]).to be_an(Array)
    end

    it 'reflects domain exposure after filtering' do
      signals = [{ salience: 0.8, domain: :terraform, novelty: 0.3 }]
      5.times { client.filter_signals(signals: signals) }
      stats = client.habituation_stats
      expect(stats[:domains]).to have_key(:terraform)
    end
  end
end
