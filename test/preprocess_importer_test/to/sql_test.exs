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


  @expected  ~s(WITH upsert as (UPDATE table_keys SET  (key, key1, key2\) = ('main', 'one', 'tre'\) where key='main' RETURNING *\) INSERT INTO table_keys (key, key1, key2\) SELECT 'main', 'one', 'tre' WHERE NOT EXISTS (SELECT * FROM upsert\))

  test "should parse string for postgres" do
    text = ~s(baby's on fire)
    assert Sql.unquoted_postgres(text) == ~s('baby''s on fire')
  end

  test "should generate comman separate keys from map" do
    {keys, values} = Sql.format_keys(@map, @config.main_key)
    assert keys == "key, key1, key2"
    assert values == "'main', 'one', 'tre'"
  end

  test "should generate sql statement with upsert" do
    assert Sql.generate(@map, @config) == @expected
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
