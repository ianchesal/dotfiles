-- Thin git subprocess layer for the delay engine.
-- NOTE: vim.pack docs say plugins under site/pack/core/opt are "managed
-- exclusively by vim.pack". Running read-only git here (fetch/rev-parse) is
-- off the supported path but does not move HEAD; all checkouts go through
-- vim.pack.update().
local M = {}

local function git(args, cwd)
  local r = vim.system(vim.list_extend({ "git" }, args), { cwd = cwd, text = true }):wait()
  if r.code ~= 0 then
    return nil, vim.trim(r.stderr or ("git " .. args[1] .. " failed"))
  end
  return vim.trim(r.stdout or "")
end

function M.fetch(dir)
  return git({ "fetch", "--quiet", "--tags", "origin" }, dir)
end

-- Default branch: origin/HEAD may be absent in vim.pack's blobless clones —
-- fall back to remote query, then local HEAD.
function M.default_branch(dir)
  local out = git({ "symbolic-ref", "--short", "refs/remotes/origin/HEAD" }, dir)
  if out then
    return (out:gsub("^origin/", ""))
  end
  out = git({ "ls-remote", "--symref", "origin", "HEAD" }, dir)
  if out then
    local b = out:match("ref:%s+refs/heads/(%S+)%s+HEAD")
    if b then
      return b
    end
  end
  return git({ "symbolic-ref", "--short", "HEAD" }, dir)
end

local function ref(dir, branch)
  -- Prefer the remote-tracking ref; fixture repos in tests have no origin.
  if git({ "rev-parse", "--verify", "--quiet", "refs/remotes/origin/" .. branch }, dir) then
    return "refs/remotes/origin/" .. branch
  end
  return branch
end

function M.head_rev(dir, branch)
  local b = branch or M.default_branch(dir)
  if not b then
    return nil, "cannot determine branch"
  end
  return git({ "rev-parse", ref(dir, b) }, dir)
end

function M.is_ancestor(a, b, dir)
  local r = vim.system({ "git", "merge-base", "--is-ancestor", a, b }, { cwd = dir }):wait()
  return r.code == 0
end

-- BOOTSTRAP ONLY (first install / branch switch): date-based and therefore
-- exposed to backdating — accepted per spec. Steady-state eligibility uses
-- first-observed timestamps in delay.lua, never this.
function M.rev_before(dir, branch, before_iso)
  if not branch then
    return nil, "branch required"
  end
  return git({ "rev-list", "-1", "--first-parent", "--before=" .. before_iso, ref(dir, branch) }, dir)
end

-- Newest semver tag (vX.Y.Z) and its target rev, for tag-mode frontier.
-- Sorted by VERSION, not creatordate: tag dates are attacker-controlled
-- metadata (threat model) and backports would misorder by date anyway.
function M.latest_semver_tag(dir)
  local out = git({ "for-each-ref", "refs/tags/v[0-9]*", "--sort=-v:refname", "--format=%(refname:short)" }, dir)
  if not out or out == "" then
    return nil
  end
  for tag in out:gmatch("[^\n]+") do
    -- strict: the default lenient parse coerces junk like "v1.bad" to 1.0.0
    local v = vim.version.parse(tag, { strict = true })
    -- Skip prereleases: an rc/beta tag version-sorts above stable, and a
    -- conservative delayed updater should only ever adopt stable releases.
    if v and not v.prerelease then
      local rev = git({ "rev-list", "-1", tag }, dir)
      if not rev then
        return nil, "rev-list failed for tag " .. tag
      end
      return { tag = tag, rev = rev }
    end
  end
  return nil
end

function M.log_range(dir, from, to)
  return git({ "log", "--oneline", "--no-decorate", from .. ".." .. to }, dir) or ""
end

-- Temp blobless clone for plugins not yet on disk (seed/bootstrap).
function M.bootstrap_clone(src, branch)
  local tmp = vim.fn.tempname()
  local args = { "clone", "--quiet", "--filter=blob:none", "--no-checkout", src, tmp }
  if branch then
    vim.list_extend(args, { "--branch", branch })
  end
  local _, err = git(args, vim.uv.cwd())
  if err then
    return nil, err
  end
  return tmp
end

return M
