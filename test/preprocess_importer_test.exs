defmodule PreprocessImporterTest do
  use ExUnit.Case
  doctest PreprocessImporter

  @config %{
    main_key: "organización",
    table: "kaluz_organizaciones",
    filename: "test/fixtures/kaluz_prueba_orgs.csv",
    from: PreprocessImporter.From.Csv,
    to: PreprocessImporter.To.Sql
  }


  test "should generate sql upsert with csv file" do
    expected = "WITH upsert as (UPDATE kaluz_organizaciones SET  (area, organización) = ('Sociedad civil', 'Reconstruyendo México') where organización='Reconstruyendo México' RETURNING *) INSERT INTO kaluz_organizaciones (area, organización) SELECT 'Sociedad civil', 'Reconstruyendo México' WHERE NOT EXISTS (SELECT * FROM upsert);"
    expected2 = "WITH upsert as (UPDATE kaluz_organizaciones SET  (area, organización) = ('Gobierno', 'Reforma Educativa') where organización='Reforma Educativa' RETURNING *) INSERT INTO kaluz_organizaciones (area, organización) SELECT 'Gobierno', 'Reforma Educativa' WHERE NOT EXISTS (SELECT * FROM upsert);"
    expected3 = "WITH upsert as (UPDATE kaluz_organizaciones SET  (area, organización) = ('Sociedad civil', 'Fundación Carlos Slim') where organización='Fundación Carlos Slim' RETURNING *) INSERT INTO kaluz_organizaciones (area, organización) SELECT 'Sociedad civil', 'Fundación Carlos Slim' WHERE NOT EXISTS (SELECT * FROM upsert);"
    generated = PreprocessImporter.generate(@config)
    assert generated =~ expected
    assert generated =~ expected2
    assert generated =~ expected3
  end

  test "should generate post execute sql from csv file" do
    config = Map.put(@config, :post_execute, %{
      func: "run_psql_func",
      func_params: ["organización", "area"]
    })
    expected_with = "WITH upsert as (UPDATE kaluz_organizaciones SET  (area, organización) = ('Sociedad civil', 'Reconstruyendo México') where organización='Reconstruyendo México' RETURNING *) INSERT INTO kaluz_organizaciones (area, organización) SELECT 'Sociedad civil', 'Reconstruyendo México' WHERE NOT EXISTS (SELECT * FROM upsert);"
    expected = "run_psql_func('Reconstruyendo México', 'Sociedad civil');"
    expected2 = "run_psql_func('Fundación Carlos Slim', 'Sociedad civil');"
    expected3 = "run_psql_func('Reforma Educativa', 'Gobierno');"
    generated = PreprocessImporter.generate(config)
    assert generated =~ expected_with
    assert generated =~ expected
    assert generated =~ expected2
    assert generated =~ expected3
  end

  test "should format config" do
    config = Map.put(@config, :fields, %{
      area: %{
        type: "assoc",
        table: "kaluz_organizacion_areas",
        field: "name"
      }
    })
    #Jason produce keys as atom, but CSV produce maps with 'name' => value
    expected = Map.put(config, :ignore, ["area"])
    assert PreprocessImporter.process_config(config) == expected
  end

  test "should extract and create separate assoc" do
    config = Map.put(@config, :fields, %{
      area: %{
        table: "kaluz_organizacion_areas",
        field: "name",
        type: "assoc"
      }
    })
    generated = PreprocessImporter.generate(config)
    assert generated =~ "WITH upsert as (UPDATE kaluz_organizacion_areas SET  (name) = ('Sociedad civil') where name='Sociedad civil' RETURNING *) INSERT INTO kaluz_organizacion_areas (name) SELECT 'Sociedad civil' WHERE NOT EXISTS (SELECT * FROM upsert);"
    assert generated =~ "WITH upsert as (UPDATE kaluz_organizaciones SET  (organización) = ('Reconstruyendo México') where organización='Reconstruyendo México' RETURNING *) INSERT INTO kaluz_organizaciones (organización) SELECT 'Reconstruyendo México' WHERE NOT EXISTS (SELECT * FROM upsert);"
  end

end
