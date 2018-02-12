defmodule PreprocessImporter do
  @moduledoc """
  Documentation for PreprocessImporter.
  """

  @doc """
  Something.

  """

  def generate(filename, config) do
    g = filename
    |> config.from.parse!(config)
    |> do_generate(config)
    |> Enum.to_list()
    "#{merge_with(g, :process)}\n#{merge_with(g, :func)}"
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
        f = config.to.generate_post_func(map, config[:post_execute])
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

end
