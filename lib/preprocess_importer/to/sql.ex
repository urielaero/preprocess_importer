defmodule PreprocessImporter.To.Sql do

  alias PreprocessImporter.To

  def generate(map, config) do
    {keys, values} = To.format_keys(map, config)
                     |> To.format_string_keys()

    main_key = Map.get(config, :main_key_alias, config.main_key)
    "WITH upsert as (UPDATE #{config.table} SET  (#{keys}) = (#{values}) where #{main_key}='#{map[config.main_key]}' RETURNING *) INSERT INTO #{config.table} (#{keys}) SELECT #{values} WHERE NOT EXISTS (SELECT * FROM upsert)"
  end

  def generate_post_func(map, %{post_execute: %{func_params: func_params, func: func}} = config) do
    {_, str} = To.values_from_map(func_params, map, config)
            |> Enum.reduce({0, func}, fn (v, {n, str})->
              {n+1, String.replace(str, "$#{n}", v)}
            end)
    str
  end
  def generate_post_func(_map, _config), do: ""

  def unquoted_value("null"), do: "null"
  def unquoted_value(value) do
    "'#{String.trim(value) |> String.replace("'", "''")}'"
  end

end
