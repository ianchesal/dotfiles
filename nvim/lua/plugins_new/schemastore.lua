-- JSON/YAML schema catalog (data-only plugin, no setup()). Consumed by
-- lspconfig.lua: the jsonls/yamlls before_init hooks pull schemas in via
-- require("schemastore").json.schemas() / .yaml.schemas().
return {
  src = "https://github.com/b0o/SchemaStore.nvim",
  policy = { mode = "commit" },
}
