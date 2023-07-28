local icons = {
  indent = {
    collapsible = "─",
    prefix = "├",
    marker = "│",
    dotted_marker = "┆",
    last = "└",
    collapsed = "─",
    expanded = "┐",
  },
}

function icons:get_diagnostic(severity)
  severity = vim.diagnostic.severity[severity]
  if severity then
    local icon = self.diagnostics[severity:lower()]
    if icon then
      return icon
    end
  end
  return "!"
end

return icons
