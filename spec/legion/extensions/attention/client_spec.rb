# frozen_string_literal: true

RSpec.describe Legion::Extensions::Attention::Client do
  subject(:client) { described_class.new }

  it 'initializes with default focus manager and habituation model' do
    status = client.attention_status
    expect(status[:manual_focus]).to eq({})
    expect(status[:capacity]).to eq(Legion::Extensions::Attention::Helpers::Constants::ATTENTIONAL_CAPACITY)
  end

  it 'includes the Attention runner' do
    expect(client).to respond_to(:filter_signals)
    expect(client).to respond_to(:attention_status)
    expect(client).to respond_to(:focus_on)
    expect(client).to respond_to(:release_focus)
    expect(client).to respond_to(:habituation_stats)
  end
end
