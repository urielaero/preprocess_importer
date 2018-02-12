defmodule PreprocessImporter.From.Csv do
  def parse!(file, config) do
    file
    |> File.stream!
    |> CSV.decode!(headers: true)
    |> Flow.from_enumerable
    |> Flow.partition(key: {:key, config.main_key})
  end
end
