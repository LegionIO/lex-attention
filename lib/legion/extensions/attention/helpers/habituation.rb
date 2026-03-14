# frozen_string_literal: true

module Legion
  module Extensions
    module Attention
      module Helpers
        class Habituation
          def initialize
            @domain_exposure = Hash.new(0.0)
            @domain_last_seen = {}
          end

          def record(domain)
            domain = domain.to_sym
            @domain_exposure[domain] = [
              @domain_exposure[domain] + Constants::HABITUATION_RATE,
              Constants::HABITUATION_CEILING
            ].min
            @domain_last_seen[domain] = Time.now.utc
          end

          def level(domain)
            domain = domain.to_sym
            @domain_exposure[domain]
          end

          def apply_novelty_reset(domain, novelty: 0.5)
            domain = domain.to_sym
            return unless novelty > 0.5

            reduction = (novelty - 0.5) * Constants::NOVELTY_RESET_FACTOR
            @domain_exposure[domain] = [@domain_exposure[domain] - reduction, 0.0].max
          end

          def decay_all
            @domain_exposure.each_key do |domain|
              @domain_exposure[domain] = [
                @domain_exposure[domain] - Constants::HABITUATION_DECAY,
                0.0
              ].max
            end

            @domain_exposure.delete_if { |_, v| v <= 0.0 }
          end

          def stats
            @domain_exposure.transform_values { |v| v.round(3) }
          end

          def habituated_domains(threshold: 0.5)
            @domain_exposure.select { |_, v| v >= threshold }.keys
          end
        end
      end
    end
  end
end
