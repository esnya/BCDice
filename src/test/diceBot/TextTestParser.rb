require 'diceBot/TestParser'

class TextTestParser < TestParser
  def load(source, gameType)
    testCaseSources = source.
                      gsub("\r\n", "\n").
                      tr("\r", "\n").
                      split("============================\n").
                      map(&:chomp)

    testCases = testCaseSources.each_with_index.map do |testCaseSource, index|
      matches = testCaseSource.match(/input:\n(.+)\noutput:(.*)\nrand:(.*)/m)
      raise "invalid data: #{source.inspect}" unless matches

      input = matches[1].lines.map(&:chomp)
      output = matches[2].lstrip

      rands = matches[3].split(',').map do |randStr|
        m = randStr.match(%r{(\d+)/(\d+)})
        raise "invalid rands: #{matches[3]}" unless m

        m.captures.map(&:to_i)
      end

      DiceBotTestCase.new(gameType, index, input, output, rands)
    end
  end

  def dump(testCases)
    testCaseTexts = testCases.map do |testCase|
      [
        "input: #{testCase.input.join("\n")}",
        "output: #{testCase.output}",
        "rand: #{testCase.randsText}"
      ].join("\n")
    end

    testCaseTexts.join("\n============================\n")
  end
end
