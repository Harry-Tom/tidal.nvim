-- line_processor.lua

local TextProcessor = {}

-- private constants
local DIGIT_MIN = 48
local DIGIT_MAX = 57
local UPPERCASE_MIN = 65
local UPPERCASE_MAX = 90
local LOWERCASE_MIN = 97
local LOWERCASE_MAX = 122
local DOT = 46
local MINUS = 45
local COLON = 58
local QUOTATION_MARK = 34

-- helper: get char code (Lua doesn't have charCodeAt)
local function charCodeAt(str, idx)
  return string.byte(str, idx, idx)
end

-- Valid TidalCycles word chars
function TextProcessor.isValidTidalWordChar(character)
  local code = charCodeAt(character, 1)
  return (code >= DIGIT_MIN and code <= DIGIT_MAX)
    or (code >= UPPERCASE_MIN and code <= UPPERCASE_MAX)
    or (code >= LOWERCASE_MIN and code <= LOWERCASE_MAX)
    or (code == DOT)
    or (code == MINUS)
    or (code == COLON)
end

function TextProcessor.isQuotationMark(character)
  return charCodeAt(character, 1) == QUOTATION_MARK
end

-- Find tidal word ranges inside quotes
function TextProcessor.findTidalWordRanges(line, callback)
  local insideQuotes = false
  local startPos, endPos = nil, nil

  local lastIdentifier = nil -- last identifier seen outside quotes
  local currIdent = nil -- building identifier while outside quotes
  local funcName = nil -- function name assigned when entering a quote

  for i = 1, #line do
    local char = string.sub(line, i, i)

    -- If this char is a quotation mark, toggle quote-mode.
    -- Finalize any identifier before toggling so lastIdentifier is up-to-date.
    if TextProcessor.isQuotationMark(char) then
      if currIdent then
        lastIdentifier = currIdent
        currIdent = nil
      end

      -- entering a quote: remember the most-recent identifier seen outside quotes
      if not insideQuotes then
        funcName = lastIdentifier
      end

      insideQuotes = not insideQuotes

      -- if we just closed a quote and a tidal word was being built, flush it
      if not insideQuotes then
        if startPos ~= nil and endPos ~= nil then
          callback({
            range_start = startPos,
            range_end = endPos,
            function_name = funcName or "", -- always provide a string
          })
          startPos, endPos = nil, nil
        end
      end
    else
      if insideQuotes then
        -- accumulate tidal-word characters while inside quotes
        if TextProcessor.isValidTidalWordChar(char) then
          if startPos == nil then
            startPos = i
            endPos = i
          else
            endPos = i
          end
        else
          -- non-word char inside quotes -> flush previously found word (if any)
          if startPos ~= nil and endPos ~= nil then
            callback({
              range_start = startPos,
              range_end = endPos,
              function_name = funcName or "",
            })
            startPos, endPos = nil, nil
          end
        end
      else
        -- outside quotes: build identifiers so we always know the last one seen
        if currIdent == nil then
          if string.match(char, "[%a_]") then
            currIdent = char
          end
        else
          if string.match(char, "[%w_]") then
            currIdent = currIdent .. char
          else
            lastIdentifier = currIdent
            currIdent = nil
          end
        end
      end
    end
  end

  -- end of line: flush any word left open inside a quote
  if startPos ~= nil and endPos ~= nil then
    callback({
      range_start = startPos,
      range_end = endPos,
      function_name = funcName or "",
    })
  end
end

-- Regex patterns (Lua style)
function TextProcessor.controlPatternsRegex()
  return '()"([^"]-)"()'
  -- return [["([^"]*)"]] -- matches quoted text
end

function TextProcessor.exceptedFunctionPatterns()
  return [[numerals%s*=.*$|p%s.*$]]
end

return TextProcessor
