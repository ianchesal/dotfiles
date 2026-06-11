-- One-time migration seeding: pins.json from lazy-lock.json so day one runs
-- today's exact commits. Both nvim-treesitter and nvim-treesitter-textobjects
-- are seeded from lazy-lock.json directly: their locked revs were verified to
-- already reside on the main branch (remotes/origin/main), so no bootstrap
-- from a 30-day-old main commit is necessary.
-- Run: nvim --headless -u NONE -l nvim/scripts/seed-pins.lua
local script_path = debug.getinfo(1).source:sub(2)
local config_dir = vim.fn.fnamemodify(script_path, ":h:h")
package.path = package.path .. ";" .. config_dir .. "/lua/?.lua"
local loader = require("pack.loader")

local lock_path = config_dir .. "/lazy-lock.json"
local lock_fh = assert(io.open(lock_path, "r"), "cannot open " .. lock_path)
local lock = vim.json.decode(lock_fh:read("*a"))
lock_fh:close()

local now = os.time()
local now_iso = os.date("!%Y-%m-%dT%H:%M:%SZ", now)

local pins = { version = 1, plugins = {} }
for _, spec in ipairs(loader.collect("plugins_new", config_dir)) do
  local entry = lock[spec.name]
  assert(entry and entry.commit, "no lazy-lock entry for " .. spec.name .. " — check name mapping")
  pins.plugins[spec.name] = {
    pin = { rev = entry.commit, pinned_at = now_iso, pinned_at_epoch = now },
    observed = {},
  }
end

loader.write_pins(config_dir .. "/pins.json", pins)
print(("seeded %d pins"):format(vim.tbl_count(pins.plugins)))
