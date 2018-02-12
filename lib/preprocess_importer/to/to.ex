defmodule PreprocessImporter.To do
  def format_keys(map, config) do
    {keys, values} = map
    |> Enum.to_list
    |> do_format_keys(config)

    {keys, values}
  end

  defp do_format_keys([], _config), do: {[], []}
  defp do_format_keys([{key, value} | tail], config) do
    ignore = Map.get(config, :ignore, [])
    only = Map.get(config, :only, [key])
    cond do
      key in ignore -> do_format_keys(tail, config)
      key in only -> # when not only[], all is true... when dont in ignore...
        {next_key, next_value} = do_format_keys(tail, config)
        unquoted_value = unquoted_func(value, config)
        k = check_main_alias(key, config)
        {["#{k}" | next_key], ["#{unquoted_value}" | next_value]}
      true -> do_format_keys(tail, config) # ignore if exist only...
    end
  end

  defp check_main_alias(key, %{main_key_alias: main_key_alias, main_key: main_key}) when main_key == key do
    main_key_alias
  end
  defp check_main_alias(key, _config), do: key

  def unquoted_func(value, config) do
    # TODO config for string size, validate number, etc...
    to = Map.get(config, :to, __MODULE__)
    to.unquoted_value(value)
  end

  def unquoted_value(text), do: text

  def values_from_map([], _map, _config), do: []
  def values_from_map([k|keys], map, config) do
    # config for string size, validate number/float etc...
    value = unquoted_func(map[k], config)
    [value | values_from_map(keys, map, config)]
  end

  def format_string_keys({ks, vs}) do
    keys = Enum.join(ks, ", ")
    values = Enum.join(vs, ", ")
    {keys, values}
  end

end
