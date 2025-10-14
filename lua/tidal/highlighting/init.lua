local EventHighlights = {}

local config = require("tidal.config")
local highlights = require("tidal.highlighting.highlights")
local osc = require("tidal.highlighting.osc")

local uv = vim.uv

EventHighlights.timer = nil

local handleMessageCallback = nil

local function merge_arrays_of_tables(t1, t2)
  local res = {}
  for _, v in ipairs(t1) do
    table.insert(res, v)
  end
  for _, v in ipairs(t2) do
    table.insert(res, v)
  end
  return res
end

local function handleMessages()
  local diff = osc.diffEventLists(osc.activeMessages, osc.messageBuffer)

  for _, evt in ipairs(diff.added) do
    highlights.addHighlight(evt.id, evt.buf, evt.markerId)
  end

  for _, evt in ipairs(diff.removed) do
    highlights.removeHighlight(evt.buf, evt.markerId)
  end

  osc.activeMessages = merge_arrays_of_tables(diff.active, diff.added)

  if handleMessageCallback then
    handleMessageCallback(osc.activeMessages)
  end

  osc.messageBuffer = {}
end

local function setInterval(interval, callback)
  EventHighlights.timer = uv.new_timer()
  EventHighlights.timer:start(interval, interval, function()
    vim.schedule(callback)
  end)
end

-- And clearInterval
local function clearInterval()
  EventHighlights.timer:stop()
  EventHighlights.timer:close()
  EventHighlights.timer = nil
end

function EventHighlights.start(highlight)
  local fpsToMs = 1000 / highlight.fps
  osc.launch(highlight)
  handleMessageCallback = highlight.highlightCallback

  local baseName = config.options.boot.tidal.highlight.styles.global.baseName
  local baseStyle = config.options.boot.tidal.highlight.styles.global.style
  vim.api.nvim_set_hl(0, baseName, baseStyle)

  for id, style in pairs(highlight.styles.custom) do
    highlights.addConfigHl(id, style)
  end

  setInterval(fpsToMs, handleMessages)
end

function EventHighlights.stop()
  clearInterval()
end

return EventHighlights
