# frozen_string_literal: true

RSpec.describe Legion::Extensions::Attention::Helpers::Focus do
  let(:focus) { described_class }

  describe '.score_signal' do
    it 'returns a float between 0 and 1' do
      score = focus.score_signal({ salience: 0.5, novelty: 0.5 })
      expect(score).to be_between(0.0, 1.0)
    end

    it 'returns higher scores for high salience signals' do
      high = focus.score_signal({ salience: 0.9, novelty: 0.5 })
      low = focus.score_signal({ salience: 0.1, novelty: 0.5 })
      expect(high).to be > low
    end

    it 'reduces score with high habituation' do
      fresh = focus.score_signal({ salience: 0.5 }, habituation_level: 0.0)
      habituated = focus.score_signal({ salience: 0.5 }, habituation_level: 0.9)
      expect(fresh).to be > habituated
    end

    it 'increases score with goal relevance' do
      no_goal = focus.score_signal({ salience: 0.5 }, goal_relevance: 0.0)
      with_goal = focus.score_signal({ salience: 0.5 }, goal_relevance: 1.0)
      expect(with_goal).to be > no_goal
    end

    it 'clamps result to 1.0 max' do
      score = focus.score_signal({ salience: 1.0, novelty: 1.0 },
                                 habituation_level: 0.0, goal_relevance: 1.0)
      expect(score).to eq(1.0)
    end
  end

  describe '.extract_salience' do
    it 'returns salience from signal hash' do
      expect(focus.extract_salience({ salience: 0.7 })).to eq(0.7)
    end

    it 'falls back to attention_score' do
      expect(focus.extract_salience({ attention_score: 0.4 })).to eq(0.4)
    end

    it 'defaults to 0.0 for non-hash' do
      expect(focus.extract_salience('not a hash')).to eq(0.0)
    end

    it 'defaults to 0.0 for missing key' do
      expect(focus.extract_salience({})).to eq(0.0)
    end
  end

  describe '.extract_novelty' do
    it 'returns novelty from signal hash' do
      expect(focus.extract_novelty({ novelty: 0.8 })).to eq(0.8)
    end

    it 'defaults to 0.5' do
      expect(focus.extract_novelty({})).to eq(0.5)
    end

    it 'defaults to 0.5 for non-hash' do
      expect(focus.extract_novelty(42)).to eq(0.5)
    end
  end

  describe '.extract_domain' do
    it 'returns domain from signal hash' do
      expect(focus.extract_domain({ domain: :terraform })).to eq(:terraform)
    end

    it 'falls back to source_type' do
      expect(focus.extract_domain({ source_type: :consul })).to eq(:consul)
    end

    it 'defaults to :general' do
      expect(focus.extract_domain({})).to eq(:general)
    end

    it 'defaults to :general for non-hash' do
      expect(focus.extract_domain(nil)).to eq(:general)
    end
  end

  describe '.tag_signal' do
    it 'merges attention metadata into the signal' do
      signal = { salience: 0.8, domain: :terraform }
      tagged = focus.tag_signal(signal, attention_score: 0.75, attention_tier: :spotlight)
      expect(tagged[:attention_score]).to eq(0.75)
      expect(tagged[:attention_tier]).to eq(:spotlight)
      expect(tagged[:salience]).to eq(0.8)
    end

    it 'returns non-hash signals unchanged' do
      result = focus.tag_signal('string', attention_score: 0.5, attention_tier: :peripheral)
      expect(result).to eq('string')
    end
  end

  describe '.attention_tier' do
    it 'returns :spotlight for >= 0.7' do
      expect(focus.attention_tier(0.7)).to eq(:spotlight)
      expect(focus.attention_tier(0.95)).to eq(:spotlight)
    end

    it 'returns :peripheral for >= 0.4' do
      expect(focus.attention_tier(0.4)).to eq(:peripheral)
      expect(focus.attention_tier(0.69)).to eq(:peripheral)
    end

    it 'returns :background for >= BACKGROUND_THRESHOLD' do
      expect(focus.attention_tier(0.2)).to eq(:background)
      expect(focus.attention_tier(0.39)).to eq(:background)
    end

    it 'returns :filtered for below BACKGROUND_THRESHOLD' do
      expect(focus.attention_tier(0.19)).to eq(:filtered)
      expect(focus.attention_tier(0.0)).to eq(:filtered)
    end
  end

  describe '.deduplicate' do
    it 'removes duplicate signals by identity' do
      signals = [
        { domain: :terraform, source_type: :event, value: 'deploy' },
        { domain: :terraform, source_type: :event, value: 'deploy' },
        { domain: :vault, source_type: :event, value: 'rotate' }
      ]
      result = focus.deduplicate(signals)
      expect(result.size).to eq(2)
    end

    it 'preserves unique signals' do
      signals = [
        { domain: :a, value: 1 },
        { domain: :b, value: 2 },
        { domain: :c, value: 3 }
      ]
      expect(focus.deduplicate(signals).size).to eq(3)
    end

    it 'returns empty array for empty input' do
      expect(focus.deduplicate([])).to eq([])
    end
  end
end
