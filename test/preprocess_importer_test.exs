defmodule PreprocessImporterTest do
  use ExUnit.Case
  doctest PreprocessImporter

  @config %{
    main_key: "organización",
    area: %{
      table: "kaluz_organizacion_areas",
      type: "insert_if_not_exists"
    },
    table: "kaluz_organizaciones",
    from: PreprocessImporter.From.Csv,
    to: PreprocessImporter.To.Sql
  }


  test "should generate sql upsert with csv file" do
    expected = "WITH upsert as (UPDATE kaluz_organizaciones SET  (area, organización) = ('Sociedad civil', 'Reconstruyendo México') where organización='Reconstruyendo México' RETURNING *) INSERT INTO kaluz_organizaciones (area, organización) SELECT 'Sociedad civil', 'Reconstruyendo México' WHERE NOT EXISTS (SELECT * FROM upsert);"
    expected2 = "WITH upsert as (UPDATE kaluz_organizaciones SET  (area, organización) = ('Gobierno', 'Reforma Educativa') where organización='Reforma Educativa' RETURNING *) INSERT INTO kaluz_organizaciones (area, organización) SELECT 'Gobierno', 'Reforma Educativa' WHERE NOT EXISTS (SELECT * FROM upsert);"
    expected3 = "WITH upsert as (UPDATE kaluz_organizaciones SET  (area, organización) = ('Sociedad civil', 'Fundación Carlos Slim') where organización='Fundación Carlos Slim' RETURNING *) INSERT INTO kaluz_organizaciones (area, organización) SELECT 'Sociedad civil', 'Fundación Carlos Slim' WHERE NOT EXISTS (SELECT * FROM upsert);"
    generated = PreprocessImporter.generate("test/fixtures/kaluz_prueba_orgs.csv", @config)
    assert generated =~ expected
    assert generated =~ expected2
    assert generated =~ expected3
  end

  test "should generate post execute sql from csv file" do
    config = Map.put(@config, :post_execute, %{
      func: "run_psql_func",
      func_params: ["organización"]
    })
    expected_with = "WITH upsert as (UPDATE kaluz_organizaciones SET  (area, organización) = ('Sociedad civil', 'Reconstruyendo México') where organización='Reconstruyendo México' RETURNING *) INSERT INTO kaluz_organizaciones (area, organización) SELECT 'Sociedad civil', 'Reconstruyendo México' WHERE NOT EXISTS (SELECT * FROM upsert);"
    expected = "run_psql_func('Reconstruyendo México');"
    expected2 = "run_psql_func('Fundación Carlos Slim');"
    expected3 = "run_psql_func('Reforma Educativa');"
    generated = PreprocessImporter.generate("test/fixtures/kaluz_prueba_orgs.csv", config)
    assert generated =~ expected_with
    assert generated =~ expected
    assert generated =~ expected2
    assert generated =~ expected3
  end
end
