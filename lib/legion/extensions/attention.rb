# frozen_string_literal: true

require 'legion/extensions/attention/version'
require 'legion/extensions/attention/helpers/constants'
require 'legion/extensions/attention/helpers/focus'
require 'legion/extensions/attention/helpers/focus_manager'
require 'legion/extensions/attention/helpers/habituation'
require 'legion/extensions/attention/runners/attention'
require 'legion/extensions/attention/client'

module Legion
  module Extensions
    module Attention
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
