defmodule PreprocessImporter.To.SqlTest do
  use ExUnit.Case

  alias PreprocessImporter.To.Sql

  @map %{
    key: "main",
    key1: "one",
    key2: "tre"
  }

  @map_w_null Map.put(@map, :key3, "null")

  @config %{
    main_key: :key,
    table: :table_keys,
    to: Sql
  }

  @config_ignore Map.put(@config, :ignore, [:key1])

  @config_only Map.put(@config, :only, [:key])

  @config_main_key_alias Map.put(@config, :main_key_alias, :name)


  @expected  ~s(WITH upsert as (UPDATE table_keys SET  (key, key1, key2\) = ('main', 'one', 'tre'\) where key='main' RETURNING *\) INSERT INTO table_keys (key, key1, key2\) SELECT 'main', 'one', 'tre' WHERE NOT EXISTS (SELECT * FROM upsert\))

  test "should parse string for postgres" do
    assert Sql.unquoted_value(~s(baby's on fire )) == ~s('baby''s on fire')
  end

  test "should generate list keys and values from map with postgres scape" do
    {keys, values} = PreprocessImporter.To.format_keys(@map, @config)
    assert keys == ["key", "key1", "key2"]
    assert values == ["'main'", "'one'", "'tre'"]
  end

  test "should generate list keys and values with null value from map with postgres scape" do
    {keys, values} = PreprocessImporter.To.format_keys(@map_w_null, @config)
    assert keys == ["key", "key1", "key2", "key3"]
    assert values == ["'main'", "'one'", "'tre'", "null"]
  end

  test "should generate sql statement with upsert" do
    assert Sql.generate(@map, @config) == @expected
  end

  test "should generate sql statement with upsert and null values" do
    assert Sql.generate(@map_w_null, @config) == ~s(WITH upsert as (UPDATE table_keys SET  (key, key1, key2, key3\) = ('main', 'one', 'tre', null\) where key='main' RETURNING *\) INSERT INTO table_keys (key, key1, key2, key3\) SELECT 'main', 'one', 'tre', null WHERE NOT EXISTS (SELECT * FROM upsert\))

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
    |> Map.put(:post_execute, %{
      func: "run_post_func($0)",
      func_params: [:key]
    })
    expected = "run_post_func('main')";
    assert Sql.generate_post_func(@map, config) == expected
  end

  test "should return empty when dont exist :func key" do
    expected = "";
    assert Sql.generate_post_func(@map, @config) == expected
  end

end
