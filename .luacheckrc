files['lua'] = {
  max_line_length = 100,
  indentation = "spaces",
  ignore = {
    "631", -- allow max line length for URLs/schema definitions
  },
}

std = "luajit"

unused_args = false
allow_defined_top = true
