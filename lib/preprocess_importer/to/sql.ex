defmodule PreprocessImporter.To.Sql do

  #TODO maybe only this func, with params: keys, values and config and whit it generate the statement...
  def generate(map, config) do
    {keys, values} = format_keys(map, config)
    main_key = Map.get(config, :main_key_alias, config.main_key)
    "WITH upsert as (UPDATE #{config.table} SET  (#{keys}) = (#{values}) where #{main_key}='#{map[config.main_key]}' RETURNING *) INSERT INTO #{config.table} (#{keys}) SELECT #{values} WHERE NOT EXISTS (SELECT * FROM upsert)"
  end

  def generate_post_func(map, %{func_params: func_params, func: func}) do
    params = get_by_key(func_params, map)
    |> Enum.join(", ")
    "#{func}(#{params})"
  end
  def generate_post_func(_map, _config), do: ""

  def format_keys(map, config) do
    {keys, values} = map
    |> Enum.to_list
    |> do_format_keys(config)

    k = Enum.join(keys, ", ")
    v = Enum.join(values, ", ")
    {k, v}
  end

  defp do_format_keys([], _config), do: {[], []}
  defp do_format_keys([{key, value} | tail], config) do
    ignore = Map.get(config, :ignore, [])
    only = Map.get(config, :only, [key])
    cond do
      key in ignore -> do_format_keys(tail, config)
      key in only -> # when not only[], all is true... when dont in ignore...
        {next_key, next_value} = do_format_keys(tail, config)
        unquoted_value = unquoted_postgres(value)
        k = check_main_alias(key, config)
        {["#{k}" | next_key], ["#{unquoted_value}" | next_value]}
      true -> do_format_keys(tail, config) # ignore if exist only...
    end
  end

  defp check_main_alias(key, %{main_key_alias: main_key_alias, main_key: main_key}) when main_key == key do
    main_key_alias
  end
  defp check_main_alias(key, _config), do: key

  def unquoted_postgres(text) do
    #TODO implement max length for strings...
    "'#{String.replace(text, "'", "''")}'"
  end

  def get_by_key([], _map), do: []
  def get_by_key([k|keys], map) do
    value = unquoted_postgres(map[k])
    [value | get_by_key(keys, map)]
  end

end
