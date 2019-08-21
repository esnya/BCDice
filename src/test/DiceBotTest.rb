# -*- coding: utf-8 -*-

require 'bcdiceCore'
require 'diceBot/DiceBotLoader'
require 'cgiDiceBot'
require 'diceBot/TextTestParser'

class DiceBotTest
  def initialize(testDataPath = nil, dataIndex = nil)
    testBaseDir = File.expand_path(File.dirname(__FILE__))

    @testDataPath = testDataPath
    @dataIndex = dataIndex

    @dataDir = "#{testBaseDir}/data"
    @tableDir = "#{testBaseDir}/../../extratables"

    @bot = CgiDiceBot.new

    @testCases = []
    @errorLog = []

    @parser = TextTestParser.new

    $isDebug = !!@dataIndex
  end

  # テストを実行する
  # @return [true] テストを実行できたとき
  # @return [false] テストに失敗した、あるいは実行できなかったとき
  def execute
    readTestCases

    if @testCases.empty?
      warn('No matched test data!')
      return false
    end

    doTests

    if @errorLog.empty?
      # テスト成功
      puts('OK.')

      true
    else
      errorLog = $RUBY18_WIN ? @errorLog.map(&:tosjis) : @errorLog

      puts('[Failures]')
      puts(errorLog.join("\n===========================\n"))

      false
    end
  end

  # テストデータを読み込む
  def readTestCases
    if @testDataPath
      # 指定されたファイルが存在しない場合、中断する
      return unless File.exist?(@testDataPath)

      targetFiles = [@testDataPath]
    else
      # すべてのテストデータを読み込む
      targetFiles = Dir.glob("#{@dataDir}/*.txt")
    end

    targetFiles.each do |filename|
      next if /^_/ === File.basename(filename)

      testCases = @parser.load_file(filename)

      @testCases +=
        if @dataIndex.nil?
          testCases
        else
          testCases.select.with_index { |_testCase, index| index == @dataIndex }
        end
    end
  end

  private :readTestCases

  # 各テストを実行する
  def doTests
    @testCases.each do |testCase|
      begin
        result = executeCommand(testCase).lstrip

        unless result == testCase.output
          @errorLog << logTextForUnexpected(result, testCase)
          print('X')

          # テスト失敗、次へ
          next
        end
      rescue StandardError => e
        @errorLog << logTextForException(e, testCase)
        print('E')

        # テスト失敗、次へ
        next
      end

      # テスト成功
      print('.')
    end

    puts
  end

  # ダイスコマンドを実行する
  def executeCommand(testCase)
    rands = testCase.rands
    @bot.setRandomValues(rands)
    @bot.setTest

    result = ''
    testCase.input.each do |message|
      result += @bot.roll(message, testCase.gameType, @tableDir).first
    end

    unless rands.empty?
      result += "\nダイス残り："
      result += rands.map { |r| r.join('/') }.join(', ')
    end

    result
  end

  # 期待された出力と異なる場合のログ文字列を返す
  def logTextForUnexpected(result, testCase)
    logText = <<EOS
Game type: #{testCase.gameType}
Index: #{testCase.name}
Input:
#{indent(testCase.input)}
Expected:
#{indent(testCase.output)}
Result:
#{indent(result)}
Rands: #{testCase.randsText}
EOS

    logText.chomp
  end
  private :logTextForUnexpected

  # 例外が発生した場合のログ文字列を返す
  def logTextForException(e, testCase)
    logText = <<EOS
Game type: #{testCase.gameType}
Index: #{testCase.name}
Exception: #{e.message}
Backtrace:
#{indent(e.backtrace)}
Input:
#{indent(testCase.input)}
Expected:
#{indent(testCase.output)}
Rands: #{testCase.randsText}
EOS

    logText.chomp
  end
  private :logTextForException

  # インデントした結果を返す
  def indent(s)
    target =
      if s.is_a?(Array)
        s
      elsif s.is_a?(String)
        s.lines
      else
        raise TypeError
      end

    target.map { |line| "  #{line.chomp}" }.join("\n")
  end
  private :indent
end
