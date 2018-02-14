defmodule PreprocessImporter.Cli do

  alias PreprocessImporter.To
  alias PreprocessImporter.From

  def main(argv \\ []) do
    {parsed, err} = parse_args(argv)
    parsed[:config]
    |> read_config()
    |> config
    |> run
    |> IO.puts
  end

  def parse_args(argv) do
    {parsed, _args, _invalid} = OptionParser.parse(argv, strict: [config: :string])
    if parsed[:config] do
      expand = Path.expand(parsed[:config])
      exists = check_file(expand)
      {parsed ++ [path: expand], exists}
    else
      {parsed, "Missing --config [file] param"}
    end
  end

  defp check_file(file) do
    exist = File.exists?(file)
    unless exist do
      "file not found"
    end
  end

  def config(cfg) do
    cfg
    |> configure_from
    |> configure_to

  end

  defp configure_from(config) do
    case config[:from] do
      "csv" -> Map.put(config, :from, From.Csv)
      nil -> Map.put(config, :error, "'from' key not found")
      _ -> Map.put(config, :error, "Mal formated 'from' key")
    end
  end

  defp configure_to(config) do
    case config[:to] do
      "sql" -> Map.put(config, :to, To.Sql)
      nil -> Map.put(config, :error, "'to' key not found")
      _ -> Map.put(config, :error, "Mal formated 'to' key ")
    end
  end

  def read_config(file) do
    file
    |> File.read!()
    |> Jason.decode!(keys: :atoms)
  end

  defp run(config) do
    # check config.error...
    config
    |> PreprocessImporter.generate()
  end
end
