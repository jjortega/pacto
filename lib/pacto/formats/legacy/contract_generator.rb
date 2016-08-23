# -*- encoding : utf-8 -*-
require 'json/schema_generator'
require 'pacto/formats/legacy/contract_builder'
require 'pacto/formats/legacy/generator/filters'

module Pacto
  module Formats
    module Legacy
      class ContractGenerator
        include Logger

        def initialize(_schema_version = 'draft3',
          schema_generator = JSON::SchemaGenerator,
          validator = Pacto::MetaSchema.new,
          filters = Generator::Filters.new,
          consumer = Pacto::Consumer.new)
          @contract_builder = ContractBuilder.new(schema_generator: schema_generator, filters: filters)
          @consumer = consumer
          @validator = validator
        end

        def generate(pacto_request, pacto_response)
          return unless Pacto.generating?
          logger.debug("Generating Contract for #{pacto_request}, #{pacto_response}")
          begin
            contract_file = load_contract_file(pacto_request, pacto_response.status)

            unless File.exist? contract_file
              uri = URI(pacto_request.uri)
              FileUtils.mkdir_p(File.dirname contract_file)
              raw_contract = save(uri, pacto_request, pacto_response)
              File.write(contract_file, raw_contract)
              logger.debug("Generating #{contract_file}")

              Pacto.load_contract contract_file, uri.host
            end
          rescue => e
            raise StandardError, "Error while generating Contract #{contract_file}: #{e.message}", e.backtrace
          end
        end

        def generate_from_partial_contract(request_file, host)
          contract = Pacto.load_contract request_file, host
          request, response = @consumer.request(contract)
          save(request_file, request, response)
        end

        def save(source, request, response)
          @contract_builder.source = source
          # TODO: Get rid of the generate_contract call, just use add_example/infer_all
          @contract_builder.add_example('default', request, response).generate_contract(request, response) # .infer_all
          @contract_builder.without_examples if Pacto.configuration.generator_options[:no_examples]
          contract = @contract_builder.build_hash
          byebug
          pretty_contract = MultiJson.encode(contract, pretty: true)
          # This is because of a discrepency w/ jruby vs MRI pretty json
          pretty_contract.gsub!(/^$\n/, '')
          @validator.validate pretty_contract
          pretty_contract
        end

        private

        def load_contract_file(pacto_request, dib=nil)
          hint = Pacto::Generator.hint_for(pacto_request)
          if hint.nil?
            uri = URI(pacto_request.uri)
            path = uri.path
            basename = File.basename(path, '.json') + "_" + dib.to_s + '.json'
            File.join(Pacto.configuration.contracts_path, uri.host, File.dirname(path), basename)
          else
            File.expand_path(hint.target_file, Pacto.configuration.contracts_path)
          end
        end
      end
    end
  end
end
