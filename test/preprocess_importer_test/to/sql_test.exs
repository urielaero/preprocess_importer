defmodule PreprocessImporter.To.SqlTest do
  use ExUnit.Case

  alias PreprocessImporter.To.Sql

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


  @expected  ~s(WITH upsert as (UPDATE table_keys SET  (key, key1, key2\) = ('main', 'one', 'tre'\) where key='main' RETURNING *\) INSERT INTO table_keys (key, key1, key2\) SELECT 'main', 'one', 'tre' WHERE NOT EXISTS (SELECT * FROM upsert\))

  test "should parse string for postgres" do
    text = ~s(baby's on fire)
    assert Sql.unquoted_postgres(text) == ~s('baby''s on fire')
  end

  test "should generate comman separate keys from map" do
    {keys, values} = Sql.format_keys(@map, @config)
    assert keys == "key, key1, key2"
    assert values == "'main', 'one', 'tre'"
  end

  test "should ignore field in generate comman separate keys from map" do
    {keys, values} = Sql.format_keys(@map, @config_ignore)
    assert keys == "key, key2"
    assert values == "'main', 'tre'"
  end

  test "should only parse field if only is set in generate comman separate keys from map" do
    {keys, values} = Sql.format_keys(@map, @config_only)
    assert keys == "key"
    assert values == "'main'"
  end

  test "should change main_key for alias if main_key_alias is set" do
    {keys, values} = Sql.format_keys(@map, @config_main_key_alias)
    assert keys == "name, key1, key2"
    assert values == "'main', 'one', 'tre'"
  end

  test "should generate sql statement with upsert" do
    assert Sql.generate(@map, @config) == @expected
  end

  test "should ignore fields with ignore flag in upsert" do
    expected =  ~s(WITH upsert as (UPDATE table_keys SET  (key, key2\) = ('main', 'tre'\) where key='main' RETURNING *\) INSERT INTO table_keys (key, key2\) SELECT 'main', 'tre' WHERE NOT EXISTS (SELECT * FROM upsert\))
    assert Sql.generate(@map, @config_ignore) == expected
  end

  test "should only fields with only flag in upsert" do
    expected =  ~s(WITH upsert as (UPDATE table_keys SET  (key\) = ('main'\) where key='main' RETURNING *\) INSERT INTO table_keys (key\) SELECT 'main' WHERE NOT EXISTS (SELECT * FROM upsert\))
    assert Sql.generate(@map, @config_only) == expected
  end

  test "should replace main_key with alias in upsert" do
    expected = ~s(WITH upsert as (UPDATE table_keys SET  (name, key1, key2\) = ('main', 'one', 'tre'\) where name='main' RETURNING *\) INSERT INTO table_keys (name, key1, key2\) SELECT 'main', 'one', 'tre' WHERE NOT EXISTS (SELECT * FROM upsert\))
    assert Sql.generate(@map, @config_main_key_alias) == expected
  end

  test "should generate post_exec function from config" do
    config = @config
    |> Map.put(:func, :run_post_func)
    |> Map.put(:func_params, [:key])
    expected = "run_post_func('main')";
    assert Sql.generate_post_func(@map, config) == expected
  end

  test "should return empty when dont exist :func key" do
    expected = "";
    assert Sql.generate_post_func(@map, @config) == expected
  end

end
