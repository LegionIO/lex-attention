# frozen_string_literal: true

RSpec.describe Legion::Extensions::Attention::Helpers::Habituation do
  subject(:model) { described_class.new }

  describe '#record' do
    it 'increases habituation level for a domain' do
      model.record(:terraform)
      expect(model.level(:terraform)).to be > 0.0
    end

    it 'accumulates with repeated recordings' do
      3.times { model.record(:terraform) }
      expect(model.level(:terraform)).to be > model.level(:vault).to_f
    end

    it 'caps at HABITUATION_CEILING' do
      ceiling = Legion::Extensions::Attention::Helpers::Constants::HABITUATION_CEILING
      20.times { model.record(:terraform) }
      expect(model.level(:terraform)).to be <= ceiling
    end

    it 'converts string domains to symbols' do
      model.record('terraform')
      expect(model.level(:terraform)).to be > 0.0
    end
  end

  describe '#level' do
    it 'returns 0.0 for unknown domains' do
      expect(model.level(:unknown)).to eq(0.0)
    end
  end

  describe '#apply_novelty_reset' do
    it 'does nothing when novelty <= 0.5' do
      model.record(:terraform)
      level_before = model.level(:terraform)
      model.apply_novelty_reset(:terraform, novelty: 0.3)
      expect(model.level(:terraform)).to eq(level_before)
    end

    it 'reduces habituation when novelty > 0.5' do
      5.times { model.record(:terraform) }
      level_before = model.level(:terraform)
      model.apply_novelty_reset(:terraform, novelty: 0.9)
      expect(model.level(:terraform)).to be < level_before
    end

    it 'never reduces below 0.0' do
      model.record(:terraform)
      model.apply_novelty_reset(:terraform, novelty: 1.0)
      expect(model.level(:terraform)).to be >= 0.0
    end
  end

  describe '#decay_all' do
    it 'reduces habituation for all recorded domains' do
      3.times { model.record(:terraform) }
      3.times { model.record(:vault) }
      tf_before = model.level(:terraform)
      v_before = model.level(:vault)

      model.decay_all
      expect(model.level(:terraform)).to be < tf_before
      expect(model.level(:vault)).to be < v_before
    end

    it 'removes domains that decay to zero' do
      model.record(:terraform)
      model.apply_novelty_reset(:terraform, novelty: 1.0)
      model.decay_all
      expect(model.stats).not_to have_key(:terraform)
    end
  end

  describe '#stats' do
    it 'returns rounded exposure levels' do
      model.record(:terraform)
      stats = model.stats
      expect(stats[:terraform]).to be_a(Float)
      expect(stats[:terraform].to_s.split('.').last.length).to be <= 3
    end
  end

  describe '#habituated_domains' do
    it 'returns domains above threshold' do
      10.times { model.record(:terraform) }
      expect(model.habituated_domains).to include(:terraform)
    end

    it 'excludes domains below threshold' do
      model.record(:terraform)
      expect(model.habituated_domains(threshold: 0.5)).not_to include(:terraform)
    end
  end
end
