defmodule PreprocessImporter.CliTest do
  use ExUnit.Case

  alias PreprocessImporter.Cli
  @config_json ["--config", "test/fixtures/config.json"]
  @config_json_path Path.expand("test/fixtures/config.json")
  @config_bad_json_path Path.expand("test/fixtures/config_bad.json")

  test "should parse argv when file exist" do
    {parsed, err} = Cli.parse_args(@config_json)
    assert parsed[:path] =~ "/"
    assert parsed[:path] =~ "/config.json"
    refute err
  end

  test "should return err if dont exist file" do
    {_parsed, err} = Cli.parse_args(["--config", "config.json"])
    assert err
  end

  test "should return err if dont config file found or exist" do
    {_parsed, err} = Cli.parse_args([])
    assert err
  end

  test "should parse config file from Jason" do
    config = Cli.read_config(@config_json_path)
              |> Cli.config()
    assert config.main_key
    assert config.from == PreprocessImporter.From.Csv
    assert config.to == PreprocessImporter.To.Sql
  end

  test "should set config.error if bad params are set in config" do
    config = Cli.read_config(@config_bad_json_path)
            |> Cli.config()
    assert config.main_key
    assert config.error
  end

  @tag :skip
  test "some" do
    Cli.main(["--config", "sandbox/config_kaluz_ccts.json"])
  end
end
