local M = {}

local table_unpack = table.unpack or unpack

local function to_string(value)
  if value == nil then
    return ""
  end
  if type(value) == "string" then
    return value
  end
  return tostring(value)
end

local function display_width(text)
  local str = to_string(text)
  if vim and vim.fn and vim.fn.strdisplaywidth then
    return vim.fn.strdisplaywidth(str)
  end
  return #str
end

local function clamp_value(value, min_value, max_value)
  if min_value and value < min_value then
    value = min_value
  end
  if max_value and value > max_value then
    value = max_value
  end
  return value
end

local function compute_column_count(rows, header)
  local max_columns = header and #header or 0
  for _, row in ipairs(rows or {}) do
    if #row > max_columns then
      max_columns = #row
    end
  end
  return max_columns
end

local function measure_content_widths(rows, header)
  local column_count = compute_column_count(rows, header)
  local widths = {}
  for column = 1, column_count do
    local max_width = 0
    if header and header[column] ~= nil then
      max_width = display_width(header[column])
    end
    for _, row in ipairs(rows or {}) do
      local value = row[column]
      local width = display_width(value)
      if width > max_width then
        max_width = width
      end
    end
    widths[column] = max_width
  end
  return widths
end

local function sum_widths(widths)
  local total = 0
  for _, width in ipairs(widths) do
    total = total + width
  end
  return total
end

local function shrink_to_available(widths, min_width, available_width, gap_width)
  if not available_width then
    return widths
  end

  local total = sum_widths(widths)
  local gaps = gap_width * math.max(#widths - 1, 0)
  if total + gaps <= available_width then
    return widths
  end

  local min_total = (min_width * #widths) + gaps
  if min_total >= available_width then
    for index = 1, #widths do
      widths[index] = min_width
    end
    return widths
  end

  local deficit = total + gaps - available_width
  local adjustable = {}
  for index, width in ipairs(widths) do
    local room = width - min_width
    if room > 0 then
      table.insert(adjustable, { index = index, room = room })
    end
  end

  while deficit > 0 and #adjustable > 0 do
    local share = math.max(1, math.floor(deficit / #adjustable))
    local next_adjustable = {}
    for _, item in ipairs(adjustable) do
      local reduce = math.min(share, item.room, deficit)
      widths[item.index] = widths[item.index] - reduce
      item.room = item.room - reduce
      deficit = deficit - reduce
      if item.room > 0 and deficit > 0 then
        table.insert(next_adjustable, item)
      end
      if deficit <= 0 then
        break
      end
    end
    adjustable = next_adjustable
  end

  return widths
end

local function clip_text(text, width)
  if width <= 0 then
    return ""
  end
  local current = to_string(text)
  if display_width(current) <= width then
    return current
  end

  local bytes = { current:byte(1, #current) }
  local left, right = 1, #bytes
  local result = current
  while left <= right do
    local mid = math.floor((left + right) / 2)
    local candidate = string.char(table_unpack(bytes, 1, mid))
    local w = display_width(candidate)
    if w > width then
      right = mid - 1
    else
      result = candidate
      left = mid + 1
    end
  end
  return result
end

local function pad_cell(text, width)
  local truncated = clip_text(text, width)
  local padding = width - display_width(truncated)
  if padding <= 0 then
    return truncated
  end
  return truncated .. string.rep(" ", padding)
end

function M.measure(rows, opts)
  opts = opts or {}
  local header = opts.header
  local separator = opts.separator or " | "
  local gap_width = display_width(separator)
  local min_width = opts.min_width or 3
  local max_width = opts.max_width or nil
  local available_width = opts.available_width
  local strategy = opts.strategy or "auto"

  local widths = measure_content_widths(rows, header)
  for index, width in ipairs(widths) do
    widths[index] = clamp_value(width, min_width, max_width)
  end

  if strategy == "fixed" then
    for index, width in ipairs(widths) do
      widths[index] = clamp_value(width, min_width, max_width)
    end
  else
    widths = shrink_to_available(widths, min_width, available_width, gap_width)
  end

  local total_width = sum_widths(widths) + gap_width * math.max(#widths - 1, 0)

  return {
    widths = widths,
    separator = separator,
    separator_width = gap_width,
    total_width = total_width,
    header = header,
    columns = #widths,
  }
end

function M.format_row(row, layout)
  local columns = layout.columns or #layout.widths
  local separator = layout.separator or " | "
  local cells = {}
  for column = 1, columns do
    local content = row and row[column] or ""
    local padded = pad_cell(content, layout.widths[column])
    cells[#cells + 1] = padded
  end
  return table.concat(cells, separator)
end

local function separator_line(layout)
  if layout.columns == 0 then
    return ""
  end
  return string.rep("-", layout.total_width)
end

function M.render(rows, layout, opts)
  opts = opts or {}
  local lines = {}
  local header = opts.header or layout.header

  if header then
    table.insert(lines, M.format_row(header, layout))
    table.insert(lines, separator_line(layout))
  end

  for _, row in ipairs(rows or {}) do
    table.insert(lines, M.format_row(row, layout))
  end

  if #lines == 0 then
    lines[1] = ""
  end

  return lines
end

return M
