# frozen_string_literal: true

RSpec.describe Legion::Extensions::Attention::Helpers::FocusManager do
  subject(:manager) { described_class.new }

  describe '#focus_on' do
    it 'focuses on a domain' do
      expect(manager.focus_on(:terraform)).to eq(:focused)
      expect(manager.focused?(:terraform)).to be true
    end

    it 'converts string domains to symbols' do
      manager.focus_on('vault')
      expect(manager.focused?(:vault)).to be true
    end

    it 'returns :already_focused for duplicate focus' do
      manager.focus_on(:terraform)
      expect(manager.focus_on(:terraform)).to eq(:already_focused)
    end

    it 'returns :capacity_full when max is reached' do
      Legion::Extensions::Attention::Helpers::Constants::MAX_MANUAL_FOCUS.times do |i|
        manager.focus_on(:"domain_#{i}")
      end
      expect(manager.focus_on(:overflow)).to eq(:capacity_full)
    end

    it 'stores reason with the focus' do
      manager.focus_on(:security, reason: 'incident response')
      expect(manager.manual_focus[:security][:reason]).to eq('incident response')
    end
  end

  describe '#release' do
    it 'releases a focused domain' do
      manager.focus_on(:terraform)
      expect(manager.release(:terraform)).to eq(:released)
      expect(manager.focused?(:terraform)).to be false
    end

    it 'returns :not_focused for unfocused domains' do
      expect(manager.release(:nonexistent)).to eq(:not_focused)
    end
  end

  describe '#focused?' do
    it 'returns true for focused domains' do
      manager.focus_on(:vault)
      expect(manager.focused?(:vault)).to be true
    end

    it 'returns false for unfocused domains' do
      expect(manager.focused?(:vault)).to be false
    end
  end

  describe '#focus_boost' do
    it 'returns FOCUS_BOOST for focused domains' do
      manager.focus_on(:terraform)
      expect(manager.focus_boost(:terraform)).to eq(
        Legion::Extensions::Attention::Helpers::Constants::FOCUS_BOOST
      )
    end

    it 'returns 0.0 for unfocused domains' do
      expect(manager.focus_boost(:terraform)).to eq(0.0)
    end
  end

  describe '#goal_relevance' do
    it 'returns 0.0 with no focus or wonders' do
      signal = { domain: :terraform, salience: 0.5 }
      expect(manager.goal_relevance(signal)).to eq(0.0)
    end

    it 'returns boost for manually focused domain' do
      manager.focus_on(:terraform)
      signal = { domain: :terraform, salience: 0.5 }
      expect(manager.goal_relevance(signal)).to be > 0.0
    end

    it 'returns relevance for domain matching an active wonder' do
      signal = { domain: :terraform, salience: 0.5 }
      wonders = [{ domain: :terraform, salience: 0.8 }]
      relevance = manager.goal_relevance(signal, active_wonders: wonders)
      expect(relevance).to be > 0.0
    end

    it 'returns 0.0 for non-matching wonder domains' do
      signal = { domain: :terraform, salience: 0.5 }
      wonders = [{ domain: :vault, salience: 0.8 }]
      relevance = manager.goal_relevance(signal, active_wonders: wonders)
      expect(relevance).to eq(0.0)
    end

    it 'caps at 1.0 even with focus and wonders combined' do
      manager.focus_on(:terraform)
      signal = { domain: :terraform, salience: 0.5 }
      wonders = [{ domain: :terraform, salience: 1.0 }]
      relevance = manager.goal_relevance(signal, active_wonders: wonders)
      expect(relevance).to be <= 1.0
    end
  end
end
