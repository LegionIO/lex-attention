# frozen_string_literal: true

module Legion
  module Extensions
    module Attention
      module Helpers
        module Focus
          module_function

          def score_signal(signal, habituation_level: 0.0, goal_relevance: 0.0)
            intrinsic = extract_salience(signal)
            novelty = extract_novelty(signal)

            weighted = (intrinsic * Constants::INTRINSIC_WEIGHT) +
                       (goal_relevance * Constants::GOAL_RELEVANCE_WEIGHT) +
                       (novelty * Constants::NOVELTY_WEIGHT) +
                       ((1.0 - habituation_level) * Constants::HABITUATION_WEIGHT)

            weighted.clamp(0.0, 1.0)
          end

          def extract_salience(signal)
            return 0.0 unless signal.is_a?(Hash)

            signal[:salience] || signal[:attention_score] || 0.0
          end

          def extract_novelty(signal)
            return 0.5 unless signal.is_a?(Hash)

            signal[:novelty] || 0.5
          end

          def extract_domain(signal)
            return :general unless signal.is_a?(Hash)

            signal[:domain] || signal[:source_type] || :general
          end

          def tag_signal(signal, attention_score:, attention_tier:)
            return signal unless signal.is_a?(Hash)

            signal.merge(attention_score: attention_score, attention_tier: attention_tier)
          end

          def attention_tier(score)
            if score >= 0.7    then :spotlight
            elsif score >= 0.4 then :peripheral
            elsif score >= Constants::BACKGROUND_THRESHOLD then :background
            else :filtered
            end
          end

          def deduplicate(signals)
            seen = {}
            signals.each_with_object([]) do |signal, unique|
              key = signal_identity(signal)
              unless seen[key]
                seen[key] = true
                unique << signal
              end
            end
          end

          def signal_identity(signal)
            return signal.object_id unless signal.is_a?(Hash)

            [signal[:source_type], signal[:domain], signal[:value]].hash
          end
        end
      end
    end
  end
end
