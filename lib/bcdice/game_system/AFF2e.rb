# frozen_string_literal: true

module BCDice
  module GameSystem
    class AFF2e < Base
      # ゲームシステムの識別子
      ID = 'AFF2e'

      # ゲームシステム名
      NAME = 'ADVANCED FIGHTING FANTASY 2nd Edition'

      # ゲームシステム名の読みがな
      SORT_KEY = 'あとはんすとふあいていんくふあんたしい2'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        対抗なしロール\tFF{目標値}+{補正}
        対抗ロール\tFR{能力値}+{補正}
        武器ロール\tFD[2,3,3,3,3,3,4]+{補正}
        防具ロール\tFD[0,0,0,0,1+1,1+1,2+2]+{補正}
      MESSAGETEXT

      # ダイスボットで使用するコマンドを配列で列挙する
      register_prefix('FF.+', 'FR.+', 'FD.+')

      def explicit_sign(i)
        format('%+d', i)
      end

      def eval_term(term)
        value = 0
        term.scan(/[+-]?\d+/) do |fact|
          value += fact.to_i
        end
        value
      end

      def parentheses(str)
        '(' + str + ')'
      end

      def successful_or_failed(total, diff)
        case total
        when  2
          diff <=  1 ? '成功（大成功ではない）' : '大成功！'
        when 12
          diff >= 12 ? '失敗（大失敗ではない）' : '大失敗！'
        else
          total <= diff ? '成功' : '失敗'
        end
      end

      def critical(total)
        case total
        when  2
          'ファンブル！'
        when 12
          '強打！'
        end
      end

      def clamp(i, min, max)
        if i < min
          min
        elsif i > max
          max
        else
          i
        end
      end

      def eval_game_system_specific_command(command)
        case command
        when /^FF/
          # 対抗なしロール
          # '成功' or '失敗' を出力する
          #
          md = Regexp.last_match
          term = md.post_match

          # 目標値
          diff = eval_term(term)

          dice_command = "2D6<=#{diff}"
          dice_list = @randomizer.roll_barabara(2, 6)
          total = dice_list.sum()
          dice_str = dice_list.join(",")
          expr = "#{total}[#{dice_str}]"
          succ = successful_or_failed(total, diff)
          sequence = [parentheses(dice_command), expr, succ]
        when /^FR/
          # 対抗ロール
          # 値を出力する
          #
          md = Regexp.last_match
          term = md.post_match

          # 補正値
          corr = eval_term(term)

          dice_command = "2D6#{explicit_sign corr}"
          dice_list = @randomizer.roll_barabara(2, 6)
          total = dice_list.sum()
          dice_str = dice_list.join(",")
          expr = "#{total}[#{dice_str}]#{explicit_sign corr}"
          crit = critical(total)
          sequence = [parentheses(dice_command), expr, crit, total + corr].compact
        when /^FD/
          # 武器防具ロール
          # ダメージを出力する
          #
          md = Regexp.last_match
          term = md.post_match
          md = /^\[(.+)\]/.match(term)
          unless md
            return 'ダメージスロットは必須です。'
          end

          term = md.post_match
          damage_slots = md[1].split(',').map { |t| eval_term(t) }
          if damage_slots.size != 7
            return 'ダメージスロットの長さに誤りがあります。'
          end

          # 補正値
          corr = eval_term(term)

          dice_command = "1D6#{explicit_sign corr}"
          total = @randomizer.roll_once(6)
          expr = "#{total}#{explicit_sign corr}"
          slot_number = clamp(total + corr, 1, 7)
          damage = damage_slots[slot_number - 1]
          sequence = [parentheses(dice_command), expr, total + corr, "#{damage}ダメージ"]
        end

        result = sequence.join(' ＞ ')
        return result
      end
    end
  end
end
