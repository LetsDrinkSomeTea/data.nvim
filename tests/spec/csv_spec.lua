require("plenary.busted")

local csv = require("data.datasources.csv")

describe("datasource.csv", function()
  it("parses quoted fields", function()
    local fields = csv.parse_line('"alpha","be,ta","gam""ma"')
    assert.are.same({ "alpha", "be,ta", 'gam"ma' }, fields)
  end)

  it("serializes rows with quoting", function()
    local line = csv.serialize_row({ "alpha", "be,ta", 'gam"ma' })
    assert.equals('alpha,"be,ta","gam""ma"', line)
  end)

  it("infers delimiter from extension", function()
    assert.equals("\t", csv.infer_delimiter("data/sample.tsv"))
    assert.equals(",", csv.infer_delimiter("data/sample.csv"))
    assert.equals(";", csv.infer_delimiter("data/sample.ssv"))
  end)
end)
