# frozen_string_literal: true

module Legion
  module Extensions
    module Attention
      module Helpers
        module Constants
          # Miller's law: 7 +/- 2 simultaneous attention targets
          ATTENTIONAL_CAPACITY = 7

          # Score weights
          INTRINSIC_WEIGHT = 0.3
          GOAL_RELEVANCE_WEIGHT = 0.3
          NOVELTY_WEIGHT      = 0.2
          HABITUATION_WEIGHT  = 0.2

          # Habituation
          HABITUATION_RATE    = 0.15  # how fast habituation builds per encounter
          HABITUATION_DECAY   = 0.05  # how fast habituation fades per tick without signal
          HABITUATION_CEILING = 0.95  # max habituation (never fully ignore)
          NOVELTY_RESET_FACTOR = 0.3  # how much novelty reduces habituation

          # Filtering thresholds
          BACKGROUND_THRESHOLD = 0.2  # below this, signal is tagged :background
          MINIMUM_THRESHOLD    = 0.05 # below this, signal is dropped entirely

          # Focus
          MAX_MANUAL_FOCUS    = 3     # max manually focused domains
          FOCUS_BOOST         = 0.3   # attention boost for manually focused domains
        end
      end
    end
  end
end
