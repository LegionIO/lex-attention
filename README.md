# lex-attention

Selective attention filter for the LegionIO brain-modeled cognitive architecture.

## What It Does

Models the thalamic reticular nucleus and prefrontal attention systems. Filters and prioritizes incoming signals before they enter the cognitive pipeline. Implements spotlight attention, goal-directed amplification, habituation, and capacity limits.

```ruby
client = Legion::Extensions::Attention::Client.new

# Filter incoming signals
result = client.filter_signals(
  signals: [
    { salience: 0.9, domain: :terraform, novelty: 0.8 },
    { salience: 0.1, domain: :heartbeat, novelty: 0.0 },
    { salience: 0.5, domain: :vault, novelty: 0.6 }
  ],
  active_wonders: [
    { domain: :terraform, salience: 0.7 }
  ]
)
# => { filtered: [...], spotlight: 1, peripheral: 1, background: 0, dropped: 1 }

# Manual focus
client.focus_on(domain: :security, reason: 'incident response')
client.attention_status
```

## Attention Tiers

| Tier | Score Range | Meaning |
|------|------------|---------|
| `:spotlight` | >= 0.7 | Full cognitive processing |
| `:peripheral` | >= 0.4 | Reduced processing, may promote |
| `:background` | >= 0.2 | Minimal processing, logged |
| `:filtered` | < 0.2 | Dropped entirely |

## Key Features

- **Habituation**: Repeated signals in same domain become less salient
- **Goal amplification**: Signals related to active curiosity wonders get boosted
- **Capacity limit**: Max 7 spotlight items (Miller's law)
- **Manual focus**: Direct attention to specific domains

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
