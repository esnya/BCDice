# frozen_string_literal: true

module BCDice
  module GameSystem
    class CrashWorld < Base
      # ゲームシステムの識別子
      ID = 'CrashWorld'

      # ゲームシステム名
      NAME = '墜落世界'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ついらくせかい'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・判定 CWn
        初期目標値n (必須)
        例・CW8
      INFO_MESSAGE_TEXT

      register_prefix('CW\d+')

      def eval_game_system_specific_command(command)
        result = nil

        case command
        when /CW(\d+)/i
          result = getCrashWorldRoll(Regexp.last_match(1).to_i)
        end

        return result
      end

      def getCrashWorldRoll(target)
        debug("target", target)

        output = "("
        isEnd = false
        successness = 0
        num = 0

        while !isEnd
          num = @randomizer.roll_once(12)

          # 振った数字を出力へ書き足す
          if output == "("
            output = "(#{num}"
          else
            output = "#{output}, #{num}"
          end

          if num <= target || num == 11
            # 成功/クリティカル(11)。 次回の目標値を変更して継続
            target = num
            successness += 1
          elsif num == 12
            # ファンブルなら終了。
            isEnd = true
          else
            # target < num < 11で終了
            isEnd = true
          end
        end

        if num == 12
          # ファンブルの時、成功度は0
          successness = 0
        end

        output = "#{output})  成功度 : #{successness}"

        if num == 12
          output = "#{output} ファンブル"
        end

        return output
      end
    end
  end
end
