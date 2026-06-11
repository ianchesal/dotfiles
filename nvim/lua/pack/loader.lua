-- Collects plugin specs from lua/plugins/*.lua, pins them from pins.json,
-- registers everything with one vim.pack.add() call, then runs config()
-- functions in (priority, filename) order. No merging, no lazy loading.
local M = {}

function M.plugin_name(src)
  return (src:gsub("/+$", ""):match("([^/]+)$"))
end

function M.read_pins(path)
  local f, ferr = io.open(path, "r")
  if not f then
    error(("pins.json unreadable at %s (%s) — refusing to guess. Run `rake nvim:update`."):format(path, ferr))
  end
  local raw = f:read("*a")
  f:close()
  local ok, pins = pcall(vim.json.decode, raw)
  if not ok or type(pins) ~= "table" or type(pins.plugins) ~= "table" then
    error("pins.json is corrupt — refusing to guess. Restore it from git.")
  end
  return pins
end

function M.resolve_version(name, pins)
  local entry = pins.plugins[name]
  if not entry or not entry.pin or not entry.pin.rev then
    error(("Unpinned plugin '%s'. Run `rake nvim:update` to pin it."):format(name))
  end
  return entry.pin.rev
end

function M.sort_specs(specs)
  table.sort(specs, function(a, b)
    local pa, pb = a.priority or 50, b.priority or 50
    if pa ~= pb then
      return pa < pb
    end
    return a._file < b._file
  end)
  return specs
end

-- root is explicit: the loader passes stdpath("config"); headless scripts
-- pass their own script-relative root so a worktree or pre-symlink checkout
-- never silently mixes trees.
function M.collect(dir, root)
  assert(root, "collect() requires an explicit root")
  local specs = {}
  local glob = root .. "/lua/" .. dir .. "/*.lua"
  for _, file in ipairs(vim.fn.glob(glob, false, true)) do
    local spec = dofile(file)
    assert(type(spec) == "table" and type(spec.src) == "string", file .. " must return a table with a string `src`")
    spec._file = vim.fn.fnamemodify(file, ":t")
    spec.name = spec.name or M.plugin_name(spec.src)
    table.insert(specs, spec)
  end
  return specs
end

-- Single pins writer shared by seed/update: stable jq formatting for
-- reviewable diffs, no sh -c, no temp files. jq is a runtime dependency.
function M.write_pins(path, pins)
  local r = vim.system({ "jq", "--sort-keys", "." }, { stdin = vim.json.encode(pins), text = true }):wait()
  assert(r.code == 0, "jq failed: " .. (r.stderr or ""))
  local f = assert(io.open(path, "w"))
  f:write(r.stdout)
  f:close()
end

function M.setup(opts)
  opts = opts or {}
  local root = vim.fn.stdpath("config")
  local specs = M.collect(opts.dir or "plugins", root)
  local pins = M.read_pins(root .. "/pins.json")

  -- priority orders config() below, not vim.pack.add — add order follows filename order
  local add = {}
  for _, spec in ipairs(specs) do
    table.insert(add, { src = spec.src, name = spec.name, version = M.resolve_version(spec.name, pins) })
  end
  vim.pack.add(add, { confirm = false }) -- confirm=true would block headless/fresh installs

  for _, spec in ipairs(M.sort_specs(specs)) do
    if spec.config then
      local ok, err = pcall(spec.config)
      if not ok then
        vim.notify(("config() failed for %s: %s"):format(spec.name, err), vim.log.levels.ERROR)
      end
    end
  end
end

return M
