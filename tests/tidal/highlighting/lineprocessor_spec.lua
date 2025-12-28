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
end)
