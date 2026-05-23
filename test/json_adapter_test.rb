# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "rbconfig"
require_relative "../lib/rgeo-geojson"

class JsonAdapterDirectRequireTest < Minitest::Test # :nodoc:
  # Regression test for https://github.com/rgeo/rgeo-geojson/pull/64
  #
  # Files under lib/rgeo/geo_json/ that route JSON I/O through JsonAdapter
  # must require it themselves, so a consumer requiring (for example) just
  # `rgeo/geo_json/conversion_methods` directly — on top of `rgeo` — does
  # not blow up with NameError on first call. We shell out to a fresh Ruby
  # process so the assertion isn't masked by the rest of the test suite
  # having already loaded the parent `rgeo/geo_json` file.

  def test_conversion_methods_loads_json_adapter
    assert_loads_json_adapter("rgeo/geo_json/conversion_methods")
  end

  def test_coder_loads_json_adapter
    assert_loads_json_adapter("rgeo/geo_json/coder")
  end

  private

  def assert_loads_json_adapter(leaf_path)
    lib_dir = File.expand_path("../lib", __dir__)
    script = <<~RUBY
      require "bundler/setup"
      $LOAD_PATH.unshift(#{lib_dir.inspect})
      require "rgeo"
      require #{leaf_path.inspect}
      raise "JsonAdapter not defined" unless defined?(RGeo::GeoJSON::JsonAdapter)
      raise "generate missing" unless RGeo::GeoJSON::JsonAdapter.respond_to?(:generate)
      raise "parse missing" unless RGeo::GeoJSON::JsonAdapter.respond_to?(:parse)
      puts "ok"
    RUBY
    output, status = Open3.capture2e(RbConfig.ruby, "-e", script)
    assert status.success?,
      "Direct require of #{leaf_path} returned non-zero exit:\n#{output}"
    assert_equal "ok", output.rstrip.lines.last.to_s.strip,
      "Direct require of #{leaf_path} did not emit 'ok' as final line:\n#{output}"
  end
end

class JsonAdapterDispatchTest < Minitest::Test # :nodoc:
  # Exercises the runtime dispatch path that JsonAdapter wires up at load
  # time. Guards both the constant/method-name selection (MultiJson vs
  # MultiJSON, load/dump vs parse/generate) and the positional options
  # forwarding contract.

  def test_roundtrip
    original = { "type" => "Point", "coordinates" => [1.0, 2.0] }
    encoded = RGeo::GeoJSON::JsonAdapter.generate(original)
    assert_kind_of String, encoded
    assert_equal original, RGeo::GeoJSON::JsonAdapter.parse(encoded)
  end

  def test_options_forwarded_to_underlying_adapter
    # Control: without the option, keys arrive as strings — establishes
    # that the option in the next assertion is what flipped the behavior.
    assert_equal({ "a" => 1 }, RGeo::GeoJSON::JsonAdapter.parse(%({"a":1})))
    assert_equal({ a: 1 }, RGeo::GeoJSON::JsonAdapter.parse(%({"a":1}), symbolize_key_option => true))
  end

  private

  # multi_json renamed `:symbolize_keys` -> `:symbolize_names` in 1.21.
  # Pick whichever name the underlying adapter understands so the test
  # runs cleanly on both `multi_json ~> 1.15` and `~> 1.21`.
  def symbolize_key_option
    adapter = defined?(::MultiJSON) ? ::MultiJSON : ::MultiJson
    adapter.respond_to?(:parse) ? :symbolize_names : :symbolize_keys
  end
end
