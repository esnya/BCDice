# frozen_string_literal: true

module BCDice
  module GameSystem
    class WorldOfDarkness < Base
      # ゲームシステムの識別子
      ID = 'WorldOfDarkness'

      # ゲームシステム名
      NAME = 'ワールド・オブ・ダークネス'

      # ゲームシステム名の読みがな
      SORT_KEY = 'わあるとおふたあくねす'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・判定コマンド(xSTn+y or xSTSn+y or xSTAn+y)
        　(ダイス個数)ST(難易度)+(自動成功)
        　(ダイス個数)STS(難易度)+(自動成功) ※出目10で振り足し
        　(ダイス個数)STA(難易度)+(自動成功) ※出目10は2成功 [20thルール]

        　難易度=省略時6
        　自動成功=省略時0
      INFO_MESSAGE_TEXT

      register_prefix('\d+ST.*')

      def initialize(command)
        super(command)
        @successDice = 0
        @botchDice = 0
        @rerollDice = 0
      end

      def eval_game_system_specific_command(command)
        diff = 6
        auto_success = 0

        enabled_reroll = false
        enabled_20th = false

        md = command.match(/^(\d+)(ST[SA]?)(\d+)?([+-]\d+)?/)

        dice_pool = md[1].to_i
        case md[2]
        when 'STS'
          enabled_reroll = true
        when 'STA'
          enabled_20th = true
        end
        diff = md[3].to_i if md[3]
        auto_success = md[4].to_i if md[4]

        diff = 6 if diff < 2

        sequence = []
        sequence.push "DicePool=#{dice_pool}, Difficulty=#{diff}, AutomaticSuccess=#{auto_success}"

        # 出力では Difficulty=11..12 もあり得る
        diff = 10 if diff > 10

        total_success = auto_success
        total_botch = 0

        dice, success, botch, auto_success = roll_wod(dice_pool, diff, true, enabled_20th ? 2 : 1)
        sequence.push dice.join(',')
        total_success += success
        total_botch += botch

        if enabled_reroll
          # 振り足し
          while auto_success > 0
            dice_pool = auto_success
            # 振り足しの出目1は大失敗ではない
            dice, success, botch, auto_success = roll_wod(dice_pool, diff, false)
            sequence.push dice.join(',')
            total_success += success
            total_botch += botch
          end
        end

        if total_success > 0
          sequence.push "成功数#{total_success}"
        elsif total_botch > 0
          sequence.push "大失敗"
        else
          sequence.push "失敗"
        end

        output = sequence.join(' ＞ ')
        return output
      end

      # Revised Edition
      # 出目10は1自動成功 振り足し
      # 出目1は大失敗: 成功を1つ相殺
      def roll_wod(dice_pool, diff, enabled_botch = true, auto_success_value = 1)
        # FIXME: まとめて振る
        dice = Array.new(dice_pool) do
          dice_now = @randomizer.roll_once(10)
          dice_now
        end

        dice.sort!

        success = 0
        botch = 0
        auto_success = 0

        dice.each do |d|
          case d
          when 10
            auto_success += auto_success_value
          when diff..10
            success += 1
          when 1
            botch += 1 if enabled_botch
          end
        end

        # 自動成功を成功に加算する
        success += auto_success

        if enabled_botch
          # 成功と大失敗を相殺する
          c = [success, botch].min
          success -= c
          botch -= c
        end

        return dice, success, botch, auto_success
      end
    end
  end
end
