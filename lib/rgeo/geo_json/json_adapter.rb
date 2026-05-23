# frozen_string_literal: true

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
    #
    # `options` mirrors multi_json's own signature (positional hash with
    # default `{}`) and is forwarded unchanged, so callers can pass any
    # adapter-supported option (e.g. `:symbolize_names`) through.
    module JsonAdapter
      ADAPTER = defined?(::MultiJSON) ? ::MultiJSON : ::MultiJson
      private_constant :ADAPTER

      if ADAPTER.respond_to?(:generate) && ADAPTER.respond_to?(:parse)
        def self.generate(object, options = {})
          ADAPTER.generate(object, options)
        end

        def self.parse(string, options = {})
          ADAPTER.parse(string, options)
        end
      else
        def self.generate(object, options = {})
          ADAPTER.dump(object, options)
        end

        def self.parse(string, options = {})
          ADAPTER.load(string, options)
        end
      end
    end
  end
end
