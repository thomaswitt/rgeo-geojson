# frozen_string_literal: true

require "minitest/autorun"
require "rbconfig"

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
    output = IO.popen([RbConfig.ruby, "-e", script], err: [:child, :out], &:read)
    assert_equal "ok", output.strip,
      "Direct require of #{leaf_path} broke JsonAdapter availability:\n#{output}"
  end
end
