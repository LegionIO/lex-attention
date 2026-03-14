# frozen_string_literal: true

require 'legion/extensions/attention/helpers/constants'
require 'legion/extensions/attention/helpers/focus'
require 'legion/extensions/attention/helpers/focus_manager'
require 'legion/extensions/attention/helpers/habituation'
require 'legion/extensions/attention/runners/attention'

module Legion
  module Extensions
    module Attention
      class Client
        include Runners::Attention

        def initialize(**)
          @focus_manager = Helpers::FocusManager.new
          @habituation_model = Helpers::Habituation.new
        end

        private

        attr_reader :focus_manager, :habituation_model
      end
    end
  end
end
