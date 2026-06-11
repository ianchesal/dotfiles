-- nvim/tests/loader_spec.lua — run: nvim --headless -u NONE -l nvim/tests/loader_spec.lua
package.path = package.path .. ";" .. vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ":h:h") .. "/lua/?.lua"
local loader = require("pack.loader")

-- name derivation
assert(loader.plugin_name("https://github.com/stevearc/oil.nvim") == "oil.nvim", "name derived from src URL")
assert(loader.plugin_name("https://github.com/nvim-mini/mini.ai") == "mini.ai", "dots in repo name preserved")

-- ordering: priority asc, then filename
local order = loader.sort_specs({
  { _file = "zzz", priority = 10 },
  { _file = "aaa" },
  { _file = "bbb" },
})
assert(order[1]._file == "zzz" and order[2]._file == "aaa" and order[3]._file == "bbb", "priority asc, then filename")

-- unpinned plugin is a hard error
local ok, err = pcall(loader.resolve_version, "oil.nvim", { plugins = {} })
assert(not ok and tostring(err):match("Unpinned plugin"), "missing pin must raise")
assert(tostring(err):match("rake nvim:update"), "error tells the user the fix")

-- corrupt pins.json is a hard error
local ok2 = pcall(loader.read_pins, "/nonexistent/pins.json")
assert(not ok2, "missing pins.json must raise, not guess")

-- read_pins round-trips the schema fixture
local fixture = vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ":h") .. "/fixtures/pins-example.json"
local pins = loader.read_pins(fixture)
assert(pins.plugins["oil.nvim"].pin.rev:match("aaa$"), "fixture pin readable")
assert(loader.resolve_version("oil.nvim", pins):match("aaa$"), "resolve_version returns the pinned rev")

-- write_pins formats via jq and round-trips
local tmp = vim.fn.tempname() .. ".json"
loader.write_pins(tmp, pins)
local reread = loader.read_pins(tmp)
assert(reread.plugins["oil.nvim"].pin.rev == pins.plugins["oil.nvim"].pin.rev, "write/read round-trip")
local raw = io.open(tmp):read("*a")
assert(raw:match("\n"), "jq output is multi-line (reviewable diffs)")
vim.fn.delete(tmp)

-- collect requires an explicit root
local ok3 = pcall(loader.collect, "plugins")
assert(not ok3, "collect without root must raise")

print("loader_spec OK")
