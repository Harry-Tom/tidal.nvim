--- @diagnostic disable: undefined-field

local lineProcessor = require("tidal.highlighting.lineprocessor")

local eq = assert.are.same

describe("lineprocessors", function()
  describe("isQuotationMark function", function()
    it("should detect quotation mark successfully", function()
      eq(true, lineProcessor.isQuotationMark('"'))
    end)
    it("should not detect char a as quotation mark successfully", function()
      eq(false, lineProcessor.isQuotationMark("a"))
    end)
  end)

  describe("isValidTidalWordChar function", function()
    it("should detect number successfully", function()
      eq(true, lineProcessor.isValidTidalWordChar("4"))
    end)

    it("should detect lower case char successfully", function()
      eq(true, lineProcessor.isValidTidalWordChar("h"))
    end)

    it("should detect upper case char successfully", function()
      eq(true, lineProcessor.isValidTidalWordChar("H"))
    end)

    it("should detect dot char successfully", function()
      eq(true, lineProcessor.isValidTidalWordChar("."))
    end)

    it("should detect minus char successfully", function()
      eq(true, lineProcessor.isValidTidalWordChar("-"))
    end)

    it("should detect colon char successfully", function()
      eq(true, lineProcessor.isValidTidalWordChar(":"))
    end)
  end)

  describe("findTidalWordRanges", function()
    it("finds a single tidal word inside quotes", function()
      local results = {}

      lineProcessor.findTidalWordRanges('d1 $ s "bd"', function(item)
        table.insert(results, item)
      end)

      eq({
        {
          range_start = 9,
          range_end = 10,
          function_name = "s",
          quote_index = 1,
        },
      }, results)
    end)

    it("finds multiple tidal words separated by spaces", function()
      local results = {}

      lineProcessor.findTidalWordRanges('d1 $ s "bd sn cp"', function(item)
        table.insert(results, item)
      end)

      eq({
        {
          range_start = 9,
          range_end = 10,
          function_name = "s",
          quote_index = 1,
        },
        {
          range_start = 12,
          range_end = 13,
          function_name = "s",
          quote_index = 1,
        },
        {
          range_start = 15,
          range_end = 16,
          function_name = "s",
          quote_index = 1,
        },
      }, results)
    end)

    it("handles multiple quoted sections with correct quote_index", function()
      local results = {}

      lineProcessor.findTidalWordRanges('d1 $ s "bd" "sn cp"', function(item)
        table.insert(results, item)
      end)

      eq({
        {
          range_start = 9,
          range_end = 10,
          function_name = "s",
          quote_index = 1,
        },
        {
          range_start = 14,
          range_end = 15,
          function_name = "s",
          quote_index = 2,
        },
        {
          range_start = 17,
          range_end = 18,
          function_name = "s",
          quote_index = 2,
        },
      }, results)
    end)

    it("uses the nearest identifier before quotes as function_name", function()
      local results = {}

      lineProcessor.findTidalWordRanges('d1 $ stack [s "bd sn"]', function(item)
        table.insert(results, item)
      end)

      eq({
        {
          range_start = 16,
          range_end = 17,
          function_name = "s",
          quote_index = 1,
        },
        {
          range_start = 19,
          range_end = 20,
          function_name = "s",
          quote_index = 1,
        },
      }, results)
    end)

    it("returns empty function_name if no identifier precedes quotes", function()
      local results = {}

      lineProcessor.findTidalWordRanges('"bd sn"', function(item)
        table.insert(results, item)
      end)

      eq({
        {
          range_start = 2,
          range_end = 3,
          function_name = "",
          quote_index = 1,
        },
        {
          range_start = 5,
          range_end = 6,
          function_name = "",
          quote_index = 1,
        },
      }, results)
    end)

    it("flushes the last tidal word at end of line without closing quote", function()
      local results = {}

      lineProcessor.findTidalWordRanges('d1 $ s "bd sn', function(item)
        table.insert(results, item)
      end)

      eq({
        {
          range_start = 9,
          range_end = 10,
          function_name = "s",
          quote_index = 1,
        },
        {
          range_start = 12,
          range_end = 13,
          function_name = "s",
          quote_index = 1,
        },
      }, results)
    end)

    it("ignores characters outside of quotes", function()
      local results = {}

      lineProcessor.findTidalWordRanges("d1 $ s bd sn", function(item)
        table.insert(results, item)
      end)

      eq({}, results)
    end)
  end)
end)
