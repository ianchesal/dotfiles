-- Pure decision core for time-delayed plugin updates.
-- No git, no io: callers inject observations, clocks (epoch seconds), and an
-- is_ancestor callback. Only os.date("!...", epoch) is used, which is a
-- deterministic UTC formatting of the injected epoch.
local M = {}
local DAY = 86400

-- observed: array of {rev, first_seen}, append-only, newest last.
function M.eligible(observed, now, days)
  local cutoff = now - days * DAY
  for i = #observed, 1, -1 do
    if observed[i].first_seen <= cutoff then
      return observed[i]
    end
  end
  return nil
end

-- Mutates `observed` in place; returns the same table for call-site convenience.
function M.observe(observed, frontier_rev, now)
  for _, o in ipairs(observed) do
    if o.rev == frontier_rev then
      return observed
    end
  end
  table.insert(observed, {
    rev = frontier_rev,
    first_seen = now,
    first_seen_iso = os.date("!%Y-%m-%dT%H:%M:%SZ", now),
  })
  return observed
end

function M.prune(observed, pinned_rev)
  local found = false
  for _, o in ipairs(observed) do
    if o.rev == pinned_rev then
      found = true
    end
  end
  if not found then
    -- Pin not in the log (hand-edited pin): wiping would silently restart
    -- this plugin's delay clock — keep the log intact instead.
    return observed
  end
  local out, past_pin = {}, false
  for _, o in ipairs(observed) do
    if past_pin then
      table.insert(out, o)
    end
    if o.rev == pinned_rev then
      past_pin = true
    end
  end
  return out
end

-- One plugin's full decision. git = { tip = <rev>, is_ancestor = fn(a,b) }.
-- Mutates state.observed (records the frontier). Returns
-- { action = "keep"|"update"|"diverged", rev = <target rev or nil> }.
function M.target(state, policy, git, now, default_days)
  if policy.mode == "exempt" then
    local action = M.decide(state.pin.rev, git.tip, git.is_ancestor)
    return { action = action, rev = git.tip }
  end
  M.observe(state.observed, git.tip, now)
  local days = policy.days or default_days
  local candidate = M.eligible(state.observed, now, days)
  local rev = candidate and candidate.rev or nil
  local action = M.decide(state.pin.rev, rev, git.is_ancestor)
  return { action = action, rev = rev }
end

-- is_ancestor(a, b): true when a is an ancestor of b.
-- Returns "update" | "keep" | "diverged".
function M.decide(pin_rev, candidate_rev, is_ancestor)
  if candidate_rev == nil or candidate_rev == pin_rev then
    return "keep"
  end
  if is_ancestor(candidate_rev, pin_rev) then
    return "keep" -- never downgrade
  end
  if is_ancestor(pin_rev, candidate_rev) then
    return "update"
  end
  return "diverged" -- force-push / branch rename: hold pin, warn (caller's job)
end

return M
