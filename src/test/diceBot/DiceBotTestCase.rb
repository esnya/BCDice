class DiceBotTestCase
  # ゲーム種別
  attr_reader :gameType
  # テストケース名
  attr_reader :name
  # 入力コマンド文字列の配列
  attr_reader :input
  # 期待される出力文字列
  attr_reader :output

  def initialize(gameType, name, input, output, rands)
    @gameType = gameType
    @name = name
    @input = input
    @output = output
    @rands = rands
  end

  # 乱数値の配列の複製を返す
  def rands
    @rands.dup
  end

  # 乱数値を文字列に変換して返す
  def randsText
    @rands.map { |r| "#{r[0]}/#{r[1]}" }.join(', ')
  end
end
