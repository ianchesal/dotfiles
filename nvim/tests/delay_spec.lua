-- nvim/tests/delay_spec.lua — run: nvim --headless -u NONE -l nvim/tests/delay_spec.lua
package.path = package.path .. ";" .. vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ":h:h") .. "/lua/?.lua"
local delay = require("pack.delay")
local DAY = 86400
local now = 1781136000 -- fixed; tests use injected clocks

-- eligible(): newest observation at least `days` old
local obs = {
  { rev = "old", first_seen = now - 40 * DAY },
  { rev = "mid", first_seen = now - 31 * DAY },
  { rev = "new", first_seen = now - 5 * DAY },
}
assert(delay.eligible(obs, now, 30).rev == "mid", "newest ≥30d observation wins")
assert(delay.eligible(obs, now, 45) == nil, "nothing old enough → nil")
assert(delay.eligible({}, now, 30) == nil, "empty log → nil")
local at_cutoff = { { rev = "edge", first_seen = now - 30 * DAY } }
assert(delay.eligible(at_cutoff, now, 30) ~= nil, "exactly-at-cutoff is eligible")

-- observe(): appends unseen frontier, idempotent, carries human-readable iso
local log = {}
delay.observe(log, "aaa", now)
delay.observe(log, "aaa", now + DAY)
assert(#log == 1 and log[1].first_seen == now, "re-observing same rev keeps first_seen")
assert(log[1].first_seen_iso == os.date("!%Y-%m-%dT%H:%M:%SZ", now), "iso field matches epoch")
delay.observe(log, "bbb", now + DAY)
assert(#log == 2 and log[2].rev == "bbb", "new frontier appended last")

-- prune(): drop entries at/before adopted pin
local pruned = delay.prune({ { rev = "a" }, { rev = "b" }, { rev = "c" } }, "b")
assert(#pruned == 1 and pruned[1].rev == "c", "entries ≤ pin removed")
-- unknown pin must NOT wipe the log (hand-edited pin would restart the clock)
local kept = delay.prune({ { rev = "a" }, { rev = "b" } }, "zzz")
assert(#kept == 2, "pin not in log → log unchanged")

-- decide(): never downgrade, flag divergence
local function anc(a, b) -- fake DAG: a→b→c linear; "x" diverged
  local order = { a = 1, b = 2, c = 3 }
  return order[a] ~= nil and order[b] ~= nil and order[a] < order[b]
end
assert(delay.decide("b", "c", anc) == "update", "update for descendant")
assert(delay.decide("b", "a", anc) == "keep", "ancestor target → never downgrade")
assert(delay.decide("b", "b", anc) == "keep", "keep for same rev")
assert(delay.decide("b", nil, anc) == "keep", "no eligible candidate → keep")
assert(delay.decide("b", "x", anc) == "diverged", "diverged for unrelated rev")

print("delay_spec OK")
