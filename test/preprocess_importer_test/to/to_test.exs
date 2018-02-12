defmodule PreprocessImporter.ToTest do
  use ExUnit.Case

  alias PreprocessImporter.To

  @map %{
    key: "main",
    key1: "one",
    key2: "tre"
  }

  @config %{
    main_key: :key,
    table: :table_keys
  }

  @config_ignore Map.put(@config, :ignore, [:key1])

  @config_only Map.put(@config, :only, [:key])

  @config_main_key_alias Map.put(@config, :main_key_alias, :name)

  test "should generate list keys and values from map" do
    {keys, values} = To.format_keys(@map, @config)
    assert keys == ["key", "key1", "key2"]
    assert values == ["main", "one", "tre"]
  end

  test "should generate comman separate keys from map" do
    {keys, values} = To.format_keys(@map, @config)
                     |> To.format_string_keys()
    assert keys == "key, key1, key2"
    assert values == "main, one, tre"
  end

  test "should ignore field in generate comman separate keys from map" do
    {keys, values} = To.format_keys(@map, @config_ignore)
                     |> To.format_string_keys()
    assert keys == "key, key2"
    assert values == "main, tre"
  end

  test "should only parse field if only is set in generate comman separate keys from map" do
    {keys, values} = To.format_keys(@map, @config_only)
                     |> To.format_string_keys()
    assert keys == "key"
    assert values == "main"
  end

  test "should change main_key for alias if main_key_alias is set" do
    {keys, values} = To.format_keys(@map, @config_main_key_alias)
                     |> To.format_string_keys()
    assert keys == "name, key1, key2"
    assert values == "main, one, tre"
  end

  test "should generate params from map" do
    assert To.values_from_map([:key1, :key2], @map, @config) == ["one", "tre"]
  end
end
