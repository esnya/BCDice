require 'diceBot/DiceBotTestCase'

class TestParser
  # ファイルから読み込み
  def load_file(filename)
    gameType = File.basename(filename).gsub(/\..*$/, '')
    source = File.open(filename).read

    load(source, gameType)
  end

  # 文字列から読み込み
  # returns: DiceBotTestCaseの配列
  def load(_source, _gameType)
    nil
  end

  # 文字列へ変換
  def dump(_testCases)
    nil
  end
end
