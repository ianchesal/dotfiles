-- rafamadriz/friendly-snippets — pre-built snippet collection for blink.cmp.
-- No config needed; blink picks it up via the "snippets" source automatically.
--
-- Sources:
--   - .snapshot/opts.lua [friendly-snippets] — no opts (empty table)
--   - lazy-lock.json                         — pinned to main branch commit

return {
  src = "rafamadriz/friendly-snippets",
  policy = { mode = "commit" },
}
