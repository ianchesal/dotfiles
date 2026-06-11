-- Time-delayed plugin updater. Run headless WITHOUT user config so that this
-- script's vim.pack.add() is the session's first (re-adds are no-ops and would
-- freeze update targets at startup pins):
--   nvim --headless -u NONE -l nvim/scripts/update.lua [--dry-run]
--
-- ADAPTATION NOTES (vs sketch):
--   1. _G.arg: confirmed present in -l mode; arg[0]=script, arg[1..n]=extra args.
--   2. nvim-treesitter update(): confirmed the installed main-branch rev exposes
--      require("nvim-treesitter").update() → require("nvim-treesitter.install").update()
--      which is wrapped in a custom async.Task that has :wait(timeout_ms). The
--      return value of update() IS the Task object directly (not an object with
--      :wait on it via a different interface). Call as:
--        require("nvim-treesitter").update():wait(300000)
--      This matches the sketch — no change needed.
--   3. dry-run and observations: delay.target() mutates state.observed even in
--      dry-run. Since we skip write_pins() on dry-run, those mutations are
--      intentionally discarded — the file is never updated, so observations are
--      lost. This is correct; a dry-run should not advance the delay clock.
--      No code change, documented here.
local config_dir = vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ":h:h")
package.path = package.path .. ";" .. config_dir .. "/lua/?.lua"
local delay = require("pack.delay")
local gitops = require("pack.gitops")
local loader = require("pack.loader")

local DEFAULT_DAYS = 30
-- _G.arg is available in -l mode: arg[0] = script path, arg[1..n] = extra args.
-- Reject unknown args: a typo like --dryrun must not silently run a LIVE
-- update. os.exit(1) verified to work under -l.
local dry_run = false
for i = 1, #(_G.arg or {}) do
  if _G.arg[i] == "--dry-run" then
    dry_run = true
  else
    io.stderr:write(("ERROR: unknown argument %q (did you mean --dry-run?)\n"):format(_G.arg[i]))
    os.exit(1)
  end
end

local pins = loader.read_pins(config_dir .. "/pins.json")
local specs = loader.collect("plugins", config_dir)
local pack_dir = vim.fn.stdpath("data") .. "/site/pack/core/opt/"
local now = os.time()
local now_iso = os.date("!%Y-%m-%dT%H:%M:%SZ", now)

-- Cross-check lockfile agreement. pins.json is authoritative: on drift, warn
-- loudly AND re-converge — drifted plugins join the update set so vim.pack
-- moves disk/lockfile back to the pin (e.g. after a mid-apply failure or a
-- manual in-editor vim.pack.update).
local drifted = {}
local lock_f = io.open(config_dir .. "/nvim-pack-lock.json", "r")
if lock_f then
  local ok, lock = pcall(vim.json.decode, lock_f:read("*a"))
  lock_f:close()
  if ok and lock and lock.plugins then
    for name, entry in pairs(pins.plugins) do
      local lentry = lock.plugins and lock.plugins[name]
      local lrev = lentry and lentry.rev
      if lrev and not vim.startswith(entry.pin.rev, lrev) and not vim.startswith(lrev, entry.pin.rev) then
        io.stderr:write(
          ("WARN: lockfile disagrees with pins.json for %s (%s vs %s) — re-converging to pin\n"):format(
            name,
            lrev,
            entry.pin.rev
          )
        )
        drifted[name] = true
      end
    end
  end
end

local changes, add_list, update_names = {}, {}, {}
for _, spec in ipairs(specs) do
  local dir = pack_dir .. spec.name
  local state = pins.plugins[spec.name]

  if vim.fn.isdirectory(dir) == 0 or state == nil then
    -- First install (or on-disk but unpinned, treated identically):
    -- date-based bootstrap (accepted backdating exposure, documented in spec).
    local mode = spec.policy and spec.policy.mode or "commit"
    local days = (spec.policy and spec.policy.days) or DEFAULT_DAYS
    local clone, cerr = gitops.bootstrap_clone(spec.src)
    if not clone then
      io.stderr:write(("WARN: bootstrap clone failed for %s: %s — skipped\n"):format(spec.name, cerr))
    else
      local before = os.date("!%Y-%m-%dT%H:%M:%SZ", now - days * 86400)
      local rev
      if mode == "exempt" then
        rev = gitops.head_rev(clone)
      elseif mode == "tag" then
        local t = gitops.latest_semver_tag(clone)
        rev = t and t.rev or nil
      else
        rev = gitops.rev_before(clone, gitops.default_branch(clone), before)
      end
      if rev then
        pins.plugins[spec.name] = {
          pin = { rev = rev, pinned_at = now_iso, pinned_at_epoch = now },
          observed = {},
        }
        state = pins.plugins[spec.name]
        table.insert(changes, { name = spec.name, from = "(new)", to = rev, dir = clone, tmp_clone = clone })
      else
        io.stderr:write(("WARN: no rev old enough to bootstrap %s — skipped\n"):format(spec.name))
        vim.fn.delete(clone, "rf")
      end
    end
  else
    local _, ferr = gitops.fetch(dir)
    if ferr then
      io.stderr:write(("WARN: fetch failed for %s (%s) — keeping pin\n"):format(spec.name, ferr))
    else
      local tip
      if spec.policy and spec.policy.mode == "tag" then
        local t = gitops.latest_semver_tag(dir)
        tip = t and t.rev or nil
      else
        tip = gitops.head_rev(dir)
      end
      if tip then
        local git_view = {
          tip = tip,
          is_ancestor = function(a, b)
            return gitops.is_ancestor(a, b, dir)
          end,
        }
        local t = delay.target(state, spec.policy or { mode = "commit" }, git_view, now, DEFAULT_DAYS)
        if t.action == "diverged" then
          io.stderr:write(
            ("WARN: %s target %s diverged from pin %s (force-push?) — holding pin\n"):format(
              spec.name,
              t.rev,
              state.pin.rev
            )
          )
        elseif t.action == "update" then
          table.insert(changes, { name = spec.name, from = state.pin.rev, to = t.rev, dir = dir })
          state.pin = { rev = t.rev, pinned_at = now_iso, pinned_at_epoch = now }
          state.observed = delay.prune(state.observed, t.rev)
          table.insert(update_names, spec.name)
        end
      else
        -- Tag mode with no stable semver tags (tag renamed/dropped?) or an
        -- unresolvable HEAD: without a signal this plugin would freeze forever.
        io.stderr:write(
          ("WARN: no frontier for %s (no stable tag / unresolvable HEAD) — keeping pin\n"):format(spec.name)
        )
      end
    end
  end

  -- NEVER register a plugin without a pin: a nil version would install the
  -- default-branch tip — the exact bypass the loader's hard error prevents,
  -- and -u NONE means the loader can't catch it here.
  if state and state.pin and state.pin.rev then
    table.insert(add_list, { src = spec.src, name = spec.name, version = state.pin.rev })
    if drifted[spec.name] and not vim.tbl_contains(update_names, spec.name) then
      table.insert(update_names, spec.name)
    end
  else
    io.stderr:write(("WARN: %s has no pin — not registered this run\n"):format(spec.name))
  end
end

-- Changelog (then drop bootstrap temp clones)
local ts_changed = false
for _, c in ipairs(changes) do
  print(("%-30s %s -> %s"):format(c.name, c.from:sub(1, 8), c.to:sub(1, 8)))
  print(gitops.log_range(c.dir, c.from ~= "(new)" and c.from or c.to .. "~5", c.to))
  if c.tmp_clone then
    vim.fn.delete(c.tmp_clone, "rf")
  end
  if c.name == "nvim-treesitter" then
    ts_changed = true
  end
end
if #changes == 0 then
  print("Nothing eligible to update (delay window: " .. DEFAULT_DAYS .. " days).")
end

if dry_run then
  -- Observations recorded by delay.target() above are intentionally discarded
  -- here: we skip write_pins(), so state.observed mutations never reach disk.
  -- A dry-run should not advance the delay clock.
  print("--dry-run: pins.json not written, nothing applied.")
  return
end

-- Persist pins, then register (single add — session's first) and apply.
loader.write_pins(config_dir .. "/pins.json", pins)

vim.pack.add(add_list, { confirm = false, load = false })
if #update_names > 0 then
  vim.pack.update(update_names, { force = true })
end

-- Treesitter parsers must match the pinned plugin rev — only when that pin
-- actually moved. Main-branch install API is async; wait so headless exit
-- doesn't truncate compilation.
-- ADAPTATION: confirmed via source inspection that update() returns an
-- async.Task with :wait(timeout_ms) — matches the sketch exactly.
if ts_changed then
  vim.cmd.packadd("nvim-treesitter")
  require("nvim-treesitter").update():wait(300000)
end

print("Done. Commit pins.json AND nvim-pack-lock.json together (rake nvim:commit).")
