require "action_client/engine"
require "template_test_helpers"

module ActionClient
  class IntegrationTestCase < ActiveSupport::TestCase
    include TemplateTestHelpers

    def override_configuration(configuration, &block)
      originals = configuration.dup

      yield(configuration)
    ensure
      originals.each { |key, value| configuration[key] = value }
      configuration.delete_if { |key, _| originals.keys.exclude?(key) }
    end
  end
end
