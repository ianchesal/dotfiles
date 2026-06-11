-- nvim/tests/gitops_spec.lua — run: nvim --headless -u NONE -l nvim/tests/gitops_spec.lua
package.path = package.path .. ";" .. vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ":h:h") .. "/lua/?.lua"
local gitops = require("pack.gitops")

local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
local base_env = vim.uv.os_environ()
local function sh(cmd, extra_env)
  local env = vim.tbl_extend("force", base_env, extra_env or {})
  local r = vim.system(cmd, { cwd = dir, env = env, text = true }):wait()
  assert(r.code == 0, (cmd[2] or "") .. " failed: " .. (r.stderr or ""))
  return vim.trim(r.stdout or "")
end
sh({ "git", "init", "-q", "-b", "main" })
sh({ "git", "config", "user.email", "t@t" })
sh({ "git", "config", "user.name", "t" })
local function commit(msg, when)
  sh({ "git", "commit", "-q", "--allow-empty", "-m", msg }, {
    GIT_AUTHOR_DATE = when,
    GIT_COMMITTER_DATE = when,
  })
end
commit("ancient", "2026-01-01T00:00:00Z")
local ancient = sh({ "git", "rev-parse", "HEAD" })
commit("recent", "2026-06-10T00:00:00Z")
local recent = sh({ "git", "rev-parse", "HEAD" })

assert(gitops.head_rev(dir) == recent)
assert(gitops.is_ancestor(ancient, recent, dir) == true)
assert(gitops.is_ancestor(recent, ancient, dir) == false)
-- bootstrap-only date query (uses local refs when no origin exists)
assert(gitops.rev_before(dir, "main", "2026-06-01T00:00:00Z") == ancient)
local range = gitops.log_range(dir, ancient, recent)
assert(range:match("recent"), "log_range lists commits in range")

-- latest_semver_tag: version sort (not lexical), unparseable tags skipped
sh({ "git", "tag", "v1.2.0", ancient })
sh({ "git", "tag", "v1.10.0", recent })
sh({ "git", "tag", "v1.bad", ancient }) -- matches the v[0-9]* glob but is not semver
sh({ "git", "tag", "v1.11.0-rc.1", recent }) -- prerelease: version-sorts above v1.10.0 but must be skipped
local t = gitops.latest_semver_tag(dir)
assert(t and t.tag == "v1.10.0", "stable wins: prerelease skipped, version sort beats lexical (v1.10 > v1.2)")
assert(t.rev == recent, "tag rev resolves to tagged commit")

vim.fn.delete(dir, "rf")
print("gitops_spec OK")
