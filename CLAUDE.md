# lex-attention

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Selective attention filter for brain-modeled agentic AI. Models the thalamic reticular nucleus and prefrontal attention systems, filtering and prioritizing incoming signals before they enter the cognitive pipeline. Implements Miller's Law capacity limits (7 ± 2), habituation, goal-directed amplification, and manual focus control.

## Gem Info

- **Gem name**: `lex-attention`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::Attention`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/attention/
  attention.rb                # Main extension module
  version.rb                  # VERSION = '0.1.0'
  client.rb                   # Client wrapper
  helpers/
    constants.rb              # Capacity, weights, habituation rates, thresholds
    focus.rb                  # Focus module: scoring, tier classification, deduplication
    focus_manager.rb          # FocusManager: manual focus + goal relevance
    habituation.rb            # Habituation: per-domain habituation tracking
  runners/
    attention.rb              # Runner module with 5 public methods
spec/
  (spec files)
```

## Key Constants

```ruby
ATTENTIONAL_CAPACITY  = 7      # Miller's law: 7 +/- 2 simultaneous spotlight items
INTRINSIC_WEIGHT      = 0.3    # signal's own salience
GOAL_RELEVANCE_WEIGHT = 0.3    # boost for signals related to active wonders
NOVELTY_WEIGHT        = 0.2    # novelty reduces habituation pull
HABITUATION_WEIGHT    = 0.2    # habituated domains score lower
HABITUATION_RATE      = 0.15   # habituation builds per encounter
HABITUATION_DECAY     = 0.05   # habituation fades per tick without signal
HABITUATION_CEILING   = 0.95   # never fully ignore a domain
NOVELTY_RESET_FACTOR  = 0.3    # novelty reduces habituation
BACKGROUND_THRESHOLD  = 0.2    # below this → :background
MINIMUM_THRESHOLD     = 0.05   # below this → dropped
MAX_MANUAL_FOCUS      = 3      # max manually focused domains
FOCUS_BOOST           = 0.3    # attention boost for manually focused domains
```

## Runners

### `Runners::Attention`

- `filter_signals(signals: [], active_wonders: [])` — score, tier, and bucket signals into spotlight/peripheral/background/dropped; enforces ATTENTIONAL_CAPACITY cap on spotlight
- `attention_status` — current manual_focus list, habituated domains, and capacity
- `focus_on(domain:, reason: nil)` — manually focus on a domain (max 3); boosts its signals
- `release_focus(domain:)` — remove a domain from manual focus
- `habituation_stats` — per-domain habituation levels and habituated domain list

## Helpers

### `Helpers::Focus` (module)
Pure-function helpers: `score_signal`, `attention_tier`, `tag_signal`, `extract_domain`, `extract_novelty`, `deduplicate`. Scoring: `(intrinsic * 0.3) + (goal_relevance * 0.3) + (novelty * 0.2) - (habituation * 0.2)`.

### `Helpers::FocusManager`
Manages `@manual_focus` (max 3 domains). `goal_relevance` checks signal domain against active_wonders list and applies `FOCUS_BOOST` for matches.

### `Helpers::Habituation`
Per-domain habituation tracking. `record` increases habituation by `HABITUATION_RATE`. `apply_novelty_reset` reduces habituation proportionally to novelty. `decay_all` reduces all by `HABITUATION_DECAY` per tick. `habituated_domains` returns domains above 0.7 habituation.

## Integration Points

This extension is the signal pre-processor for lex-tick. It should be called at the start of each tick to filter the incoming signal buffer before passing to cognitive phases. The `filtered` signals from `filter_signals` form the sensory input for the tick. In lex-cortex, this maps to the sensing phase. The `active_wonders` parameter connects to lex-memory: pass wonder/curiosity traces as active goals to amplify goal-relevant signals.

## Development Notes

- Signals must have `salience:` key (used as intrinsic weight), `domain:` key, and optional `novelty:` key
- Overflow from spotlight (> 7) demotes to peripheral rather than dropping
- Deduplication in `Focus.deduplicate` prevents the same domain from flooding the spotlight
- `habituation_model.decay_all` is called inside `filter_signals` — every signal filtering tick also decays habituation
