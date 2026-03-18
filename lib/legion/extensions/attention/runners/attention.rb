# frozen_string_literal: true

module Legion
  module Extensions
    module Attention
      module Runners
        module Attention
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def filter_signals(signals: [], active_wonders: [], **)
            return { filtered: [], spotlight: 0, peripheral: 0, background: 0, dropped: 0 } if signals.empty?

            unique = Helpers::Focus.deduplicate(signals)
            scored = score_all(unique, active_wonders)
            categorized = categorize(scored)

            habituation_model.decay_all

            Legion::Logging.debug "[attention] filtered #{signals.size}->#{categorized[:spotlight].size + categorized[:peripheral].size} " \
                                  "(spotlight=#{categorized[:spotlight].size} peripheral=#{categorized[:peripheral].size} " \
                                  "background=#{categorized[:background].size} dropped=#{categorized[:dropped]})"

            total_dropped = categorized[:dropped] + (@pre_filter_dropped || 0)

            {
              filtered:   categorized[:spotlight] + categorized[:peripheral],
              spotlight:  categorized[:spotlight].size,
              peripheral: categorized[:peripheral].size,
              background: categorized[:background].size,
              dropped:    total_dropped
            }
          end

          def attention_status(**)
            {
              manual_focus:       focus_manager.manual_focus,
              habituated_domains: habituation_model.habituated_domains,
              habituation_stats:  habituation_model.stats,
              capacity:           Helpers::Constants::ATTENTIONAL_CAPACITY,
              focus_count:        focus_manager.manual_focus.size
            }
          end

          def focus_on(domain:, reason: nil, **)
            result = focus_manager.focus_on(domain, reason: reason)
            Legion::Logging.info "[attention] focus_on #{domain}: #{result}"
            { status: result, domain: domain }
          end

          def release_focus(domain:, **)
            result = focus_manager.release(domain)
            Legion::Logging.info "[attention] release_focus #{domain}: #{result}"
            { status: result, domain: domain }
          end

          def habituation_stats(**)
            { domains: habituation_model.stats, habituated: habituation_model.habituated_domains }
          end

          private

          def focus_manager
            @focus_manager ||= Helpers::FocusManager.new
          end

          def habituation_model
            @habituation_model ||= Helpers::Habituation.new
          end

          def score_all(signals, active_wonders)
            @pre_filter_dropped = 0
            signals = signals.reject do |signal|
              salience = Helpers::Focus.extract_salience(signal)
              if salience < Helpers::Constants::MINIMUM_THRESHOLD
                @pre_filter_dropped += 1
                true
              end
            end

            signals.map do |signal|
              domain = Helpers::Focus.extract_domain(signal)
              habituation_model.record(domain)

              novelty = Helpers::Focus.extract_novelty(signal)
              habituation_model.apply_novelty_reset(domain, novelty: novelty)

              goal_rel = focus_manager.goal_relevance(signal, active_wonders: active_wonders)
              hab_level = habituation_model.level(domain)
              score = Helpers::Focus.score_signal(signal, habituation_level: hab_level, goal_relevance: goal_rel)
              tier = Helpers::Focus.attention_tier(score)

              Helpers::Focus.tag_signal(signal, attention_score: score, attention_tier: tier)
            end
          end

          def categorize(scored_signals)
            result = { spotlight: [], peripheral: [], background: [], dropped: 0 }

            scored_signals.each do |signal|
              case signal[:attention_tier]
              when :spotlight  then result[:spotlight] << signal
              when :peripheral then result[:peripheral] << signal
              when :background then result[:background] << signal
              else result[:dropped] += 1
              end
            end

            enforce_capacity(result)
          end

          def enforce_capacity(categorized)
            capacity = Helpers::Constants::ATTENTIONAL_CAPACITY
            spotlight = categorized[:spotlight].sort_by { |s| -(s[:attention_score] || 0) }

            if spotlight.size > capacity
              overflow = spotlight[capacity..]
              categorized[:spotlight] = spotlight.first(capacity)
              categorized[:peripheral].concat(overflow)
            end

            categorized
          end
        end
      end
    end
  end
end
