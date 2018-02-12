defmodule PreprocessImporter.To.Sql do

  def generate(map, config) do
    {keys, values} = format_keys(map, config.main_key)
    "WITH upsert as (UPDATE #{config.table} SET  (#{keys}) = (#{values}) where #{config.main_key}='#{map[config.main_key]}' RETURNING *) INSERT INTO #{config.table} (#{keys}) SELECT #{values} WHERE NOT EXISTS (SELECT * FROM upsert)"
  end

  def generate_post_func(map, %{func_params: func_params, func: func}) do
    params = get_by_key(func_params, map)
    |> Enum.join(", ")
    "#{func}(#{params})"
  end
  def generate_post_func(_map, _config), do: ""

  def format_keys(map, main_key) do
    {keys, values} = map
    |> Enum.to_list
    |> do_format_keys(main_key)

    k = Enum.join(keys, ", ")
    v = Enum.join(values, ", ")
    {k, v}
  end

  defp do_format_keys([], _main_key), do: {[], []}
  #defp do_format_keys([{key, _value} | tail], main_key) when key == main_key, do: do_format_keys(tail, main_key)
  defp do_format_keys([{key, value} | tail], main_key) do
    {next_key, next_value} = do_format_keys(tail, main_key)
    unquoted_value = unquoted_postgres(value)
    {["#{key}" | next_key], ["#{unquoted_value}" | next_value]}
  end

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
