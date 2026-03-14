# frozen_string_literal: true

module Legion
  module Extensions
    module Attention
      module Helpers
        class FocusManager
          attr_reader :manual_focus

          def initialize
            @manual_focus = {}
          end

          def focus_on(domain, reason: nil)
            domain = domain.to_sym
            return :already_focused if @manual_focus.key?(domain)
            return :capacity_full if @manual_focus.size >= Constants::MAX_MANUAL_FOCUS

            @manual_focus[domain] = { reason: reason, focused_at: Time.now.utc }
            :focused
          end

          def release(domain)
            domain = domain.to_sym
            return :not_focused unless @manual_focus.key?(domain)

            @manual_focus.delete(domain)
            :released
          end

          def focused?(domain)
            @manual_focus.key?(domain.to_sym)
          end

          def focus_boost(domain)
            focused?(domain) ? Constants::FOCUS_BOOST : 0.0
          end

          def goal_relevance(signal, active_wonders: [])
            domain = Focus.extract_domain(signal)
            base_relevance = focus_boost(domain)

            wonder_relevance = compute_wonder_relevance(signal, active_wonders)
            [base_relevance + wonder_relevance, 1.0].min
          end

          private

          def compute_wonder_relevance(signal, active_wonders)
            return 0.0 if active_wonders.empty?

            domain = Focus.extract_domain(signal)
            matching = active_wonders.select { |w| w.is_a?(Hash) && w[:domain] == domain }
            return 0.0 if matching.empty?

            max_score = matching.map { |w| w[:salience] || 0.5 }.max
            max_score * 0.5
          end
        end
      end
    end
  end
end
