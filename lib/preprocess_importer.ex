defmodule PreprocessImporter do
  @moduledoc """
  Documentation for PreprocessImporter.
  """

  @doc """
  Something.

  """

  def generate(config) do
    cf = process_config(config)
    filename = config.filename
    |> config.from.parse!(cf)
    |> do_generate(cf)
    |> Enum.to_list()
    pre = generate_from_assocs(config)
    pre <> "#{merge_with(filename, :process)}\n#{merge_with(filename, :func)}"
  end

  defp do_generate(data, config) do
    Flow.reduce(data, fn ->
      %{exists: %{},
      data: [],
      process: [],
      func: []}
    end, fn(map, acc) ->
      key = map[config.main_key]
      if acc[:exists][key] do # skip repeat items by main_key
        acc
      else
        update_lists(config, key, map, acc)
      end
    end)
  end

  defp update_lists(config, key, map, acc) do
    exists = Map.put(acc.exists, key, true)
    data = [map | acc.data]
    g = config.to.generate(map, config)
    process = [g | acc.process]
    f = config.to.generate_post_func(map, config)
    func = [f | acc.func]
    %{acc | exists: exists, data: data, process: process, func: func}
  end

  defp merge_with([], _key_name), do: ""
  defp merge_with([{key, values} | tail], key_name) when key == key_name do
    merge(values) <> merge_with(tail, key_name)
  end
  defp merge_with([_other | tail], key_name), do: merge_with(tail, key_name)

  defp merge([]), do: ""
  defp merge([p|tail]) when p == "", do: "#{merge(tail)}"
  defp merge([p|tail]),
    do: "#{p};\n#{merge(tail)}"

  def process_config(config) do
    ignore = Map.get(config, :ignore, [])
    fields = config
    |> Map.get(:fields, %{})
    |> Enum.to_list()
    ig = ignore ++ ignore_fields(fields)
    Map.put(config, :ignore, ig)
  end

  defp generate_from_assocs(%{fields: fields} = config) do
    fields
    |> Enum.to_list()
    |> do_generate_from_assocs(config)
  end
  defp generate_from_assocs(_cfg), do: ""

  defp do_generate_from_assocs([], _config), do: ""
  defp do_generate_from_assocs([{key, %{type: type} = field} | tail], config) when type == "assoc" do
    config_assoc = %{
      main_key: "#{key}",
      table: field.table,
      from: config.from,
      to: config.to,
      only: ["#{key}"],
      main_key_alias: field.field,
      filename: config.filename
    }
    generate(config_assoc) <> do_generate_from_assocs(tail, config)
  end
  defp do_generate_from_assocs([_field | tail], config), do: do_generate_from_assocs(tail, config)


  @ignore_list ["assoc"]

  defp ignore_fields([]), do: []
  defp ignore_fields([{key, %{type: type}}|tail]) when type in @ignore_list do
    ["#{key}"|ignore_fields(tail)]
  end
  defp ignore_fields([_value|tail]), do: ignore_fields(tail)

end
