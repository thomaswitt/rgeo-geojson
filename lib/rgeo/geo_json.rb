# frozen_string_literal: true

require "rgeo"
require_relative "geo_json/version"
require_relative "geo_json/conversion_methods"
require_relative "geo_json/entities"
require_relative "geo_json/coder"
require_relative "geo_json/interface"
require "multi_json"

module RGeo
  module GeoJSON
    # Thin shim over multi_json that picks the canonical constant and
    # method names available at load time. multi_json 1.21 renamed
    # `MultiJson` -> `MultiJSON` and `load`/`dump` -> `parse`/`generate`;
    # the legacy names still work but each emit a one-shot deprecation
    # warning. Resolving the dispatch once at require time avoids the
    # warnings on 1.21+ while staying compatible with the existing
    # `~> 1.15` dependency floor.
    module JsonAdapter
      ADAPTER = defined?(::MultiJSON) ? ::MultiJSON : ::MultiJson
      private_constant :ADAPTER

      module_function

      if ADAPTER.respond_to?(:generate)
        def generate(object) = ADAPTER.generate(object)
        def parse(string) = ADAPTER.parse(string)
      else
        def generate(object) = ADAPTER.dump(object)
        def parse(string) = ADAPTER.load(string)
      end
    end
  end
end
