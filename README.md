[![Gem Version](https://badge.fury.io/rb/pacto.png)](http://badge.fury.io/rb/pacto)
[![Build Status](https://travis-ci.org/thoughtworks/pacto.png)](https://travis-ci.org/thoughtworks/pacto)
[![Code Climate](https://codeclimate.com/github/thoughtworks/pacto.png)](https://codeclimate.com/github/thoughtworks/pacto)
[![Dependency Status](https://gemnasium.com/thoughtworks/pacto.png)](https://gemnasium.com/thoughtworks/pacto)
[![Coverage Status](https://coveralls.io/repos/thoughtworks/pacto/badge.png)](https://coveralls.io/r/thoughtworks/pacto)

# Pacto

Pacto is a Ruby framework to help with [Integration Contract Testing](http://martinfowler.com/bliki/IntegrationContractTest.html).

**If you're viewing this at https://github.com/thoughtworks/pacto,
you're reading the documentation for the master branch.
[View documentation for the latest release
(0.2.5).](https://github.com/thoughtworks/pacto/tree/v0.2.5)**

With Pacto you can:

* [Evolve](https://www.relishapp.com/maxlinc/pacto/docs/evolve) your services with either a [Consumer-Driven Contracts](http://martinfowler.com/articles/consumerDrivenContracts.html) approach or by tracking provider contracts.
* [Generate](https://www.relishapp.com/maxlinc/pacto/docs/generate) a contract from your documentation or sample response.
* [Validate](https://www.relishapp.com/maxlinc/pacto/docs/validate) your live or stubbed services against expectations to ensure they still comply with your Contracts.
* [Stub](https://www.relishapp.com/maxlinc/pacto/docs/stub) services by letting Pacto creates responses that match a Contract.

See the [Usage](#usage) section for some basic examples on how you can use Pacto, and browse the [Relish documentation](https://www.relishapp.com/maxlinc/pacto) for more advanced options.

Pacto's contract validation capabilities are primarily backed by [json-schema](http://json-schema.org/).  This lets you the power of many assertions that will give detailed and precise error messages.  See the specification for possible assertions.

Pacto's stubbing ability ranges from very simple stubbing to:
* Running a server to test from non-Ruby clients
* Generating random or dynamic data as part of the response
* Following simple patterns to simulate resource collections

It's your choice - do you want simple behavior and strict contracts to focus on contract testing, or rich behavior and looser contracts to create dynamic test doubles for collaboration testing?

Note: Currently, Pacto is only designed to work with JSON services.  See the [Constraints](#constraints) section for further information on what Pacto does not do.

## Usage

Pacto can perform three activities: generating, validating, or stubbing services.  You can do each of these activities against either live or stubbed services.

### Configuration

In order to start with Pacto, you just need to require it and optionally customize the default [Configuration](https://www.relishapp.com/maxlinc/pacto/docs/configuration).  For example:

```ruby
require 'pacto'

Pacto.configure do |config|
  config.contracts_path = 'contracts'
end
```

### Generating

The easiest way to get started with Pacto is to run a suite of live tests and tell Pacto to generate the contracts:

```ruby
Pacto.generate!
# run your tests
```

If you're using the same configuration as above, this will produce Contracts in the contracts/ folder.

We know we cannot generate perfect Contracts, especially if we only have one sample request.  So we do our best to give you a good starting point, but you will likely want to customize the contract so the validation is more strict in some places and less strict in others.

### Contract Lists

In order to stub or validate or stub a group of contracts you need to create a ContractList.
A ContractList represent a collection of endpoints attached to the same host.

```ruby
require 'pacto'

default_contracts = Pacto.build_contracts('contracts/services', 'http://example.com')
authentication_contracts = Pacto.build_contracts('contracts/auth', 'http://example.com')
legacy_contracts = Pacto.build_contracts('contracts/legacy', 'http://example.com')
```

### Validating

Once you have a ContractList, you can validate all the contracts against the live host.

```ruby
contracts = Pacto.build_contracts('contracts/services', 'http://example.com')
contracts.validate_all
```

This method will hit the real endpoint, with a request created based on the request part of the contract.  
The response will be compared against the response part of the contract and any structural difference will
generate a validation error.

Running this in your build pipeline will ensure that your contracts actually match the real world, and that 
you can run your acceptance tests against the contract stubs without worries.

### Stubbing

To generate stubs based on a ContractList you can run:

```ruby
contracts = Pacto.build_contracts('contracts/services', 'http://example.com')
contracts.stub_all
```

This method uses webmock to ensure that whenever you make a request against one of contracts you actually get a stubbed response,
based on the default values specified on the contract, instead of hitting the real provider. 

You can override any default value on the contracts by providing a hash of optional values to the stub_all method. This
will override the keys for every contract in the list

```ruby
contracts = Pacto.build_contracts('contracts/services', 'http://example.com')
contracts.stub_all(request_id: 14, name: "Marcos")
```

## Pacto Server (non-Ruby usage)

It is really easy to embed Pacto inside a small server.  We haven't bundled a server inside of Pacto, but check out [pacto-demo](https://github.com/thoughtworks/pacto-demo) to see how easily you can expose Pacto via server.

That demo lets you easily run a server in several modes:
```sh
$ bundle exec ruby pacto_server.rb -sv --generate
# Runs a server that will generate Contracts for each request received
$ bundle exec ruby pacto_server.rb -sv --validate
# Runs the server that provides stubs and checks them against Contracts
$ bundle exec ruby pacto_server.rb -sv --validate --host http://example.com
# Runs the server that acts as a proxy to http://example.com, validating each request/response against a Contract
```

## Rake Tasks

Pacto includes a few Rake tasks to help with common tasks.  If you want to use these tasks, just add this top your Rakefile:

```ruby
require 'pacto/rake_task'
```

This should add several new tasks to you project:
```sh
rake pacto:generate[input_dir,output_dir,host]  # Generates contracts from partial contracts
rake pacto:meta_validate[dir]                   # Validates a directory of contract definitions
rake pacto:validate[host,dir]                   # Validates all contracts in a given directory against a given host
```

The pacto:generate task will take partially defined Contracts and generate the missing pieces.  See [Generate](https://www.relishapp.com/maxlinc/pacto/docs/generate) for more details.

The pacto:meta_validate task makes sure that your Contracts are valid.  It only checks the Contracts, not the services that implement them.

The pacto:validate task sends a request to an actual provider and ensures their response complies with the Contract.

## Contracts

Pacto works by associating a service with a Contract.  The Contract is a JSON description of the service that uses json-schema to describe the response body.  You don't need to write your contracts by hand.  In fact, we recommend generating a Contract from your documentation or a service.

A contract is composed of a request that has:

- Method: the method of the HTTP request (e.g. GET, POST, PUT, DELETE);
- Path: the relative path (without host) of the provider's endpoint;
- Headers: headers sent in the HTTP request;
- Params: any data or parameters of the HTTP request (e.g. query string for GET, body for POST).

And a response has that has:

- Status: the HTTP response status code (e.g. 200, 404, 500);
- Headers: the HTTP response headers;
- Body: a JSON Schema defining the expected structure of the HTTP response body.

Below is an example contract for a GET request
to the /hello_world endpoint of a provider:

```json
{
  "request": {
    "method": "GET",
    "path": "/hello_world",
    "headers": {
      "Accept": "application/json"
    },
    "params": {}
  },

  "response": {
    "status": 200,
    "headers": {
      "Content-Type": "application/json"
    },
    "body": {
      "description": "A simple response",
      "type": "object",
      "properties": {
        "message": {
          "type": "string"
        }
      }
    }
  }
}
```

## Constraints

- Pacto only works with JSON services
- Pacto requires Ruby 1.9.3 or newer (though you can older Rubies or non-Ruby projects with a [Pacto Server](#pacto-server-non-ruby-usage))
- Pacto cannot currently specify multiple acceptable status codes (e.g. 200 or 201)

## Contributing

Read the CONTRIBUTING.md file.
