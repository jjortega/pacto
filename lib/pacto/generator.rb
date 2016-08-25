# -*- encoding : utf-8 -*-
require 'pacto/formats/legacy/contract_generator'
require 'pacto/formats/legacy/generator_hint'

module Pacto
  module Generator

    class << self
      include Logger
      # Factory method to return the active contract generator implementation
      def contract_generator
        Pacto::Formats::Legacy::ContractGenerator.new
      end

      # Factory method to return the active contract generator implementation
      def schema_generator
        JSON::SchemaGenerator
      end

      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end

      def hint_for(pacto_request)
        logger.debug("Pacto Request: " + pacto_request.params + " - - " + pacto_request.path)
        configuration.hints.find { |hint| hint.matches? pacto_request }
        logger.debug("Pacto Request: " + configuration.hints)
      end
    end

    class Configuration
      attr_reader :hints

      def initialize
        @hints = Set.new
      end

      def hint(name, hint_data)
        @hints << Formats::Legacy::GeneratorHint.new(hint_data.merge(service_name: name))
      end
    end
  end
end
