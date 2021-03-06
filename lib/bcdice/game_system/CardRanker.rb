# frozen_string_literal: true

module BCDice
  module GameSystem
    class CardRanker < Base
      # ゲームシステムの識別子
      ID = 'CardRanker'

      # ゲームシステム名
      NAME = 'カードランカー'

      # ゲームシステム名の読みがな
      SORT_KEY = 'かあとらんかあ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ランダムでモンスターカードを選ぶ (RM) (RTTn n：色番号、省略可能)
        ランダム分野表 RCT
        特定のモンスターカードを選ぶ (CMxy　x：色、y：番号）
        　白：W、青：U、緑：V、金：G、赤：R、黒：B
        　例）CMW1→白の2：白竜　CMG12→金の12：土精霊
        場所表 (ST)
        街中場所表 (CST)
        郊外場所表 (OST)
        学園場所表 (GST)
        運命表 (DT)
        大会運命表 (TDT)
        学園運命表 (GDT)
        崩壊運命表 (CDT)
      INFO_MESSAGE_TEXT

      def initialize(command)
        super(command)

        @sort_add_dice = true
        @d66_sort_type = D66SortType::ASC
      end

      # ゲーム別成功度判定(2D6)
      def check_2D6(total, dice_total, _dice_list, cmp_op, target)
        return '' if target == '?'
        return '' unless cmp_op == :>=

        if dice_total <= 2
          return " ＞ ファンブル"
        elsif dice_total >= 12
          return " ＞ スペシャル ＞ " + RTT.roll_command(@randomizer, "RM")
        elsif total >= target
          return " ＞ 成功"
        else
          return " ＞ 失敗"
        end
      end

      def eval_game_system_specific_command(command)
        roll_tables(command, TABLES) || get_monster(command) || RTT.roll_command(randomizer, command)
      end

      COLOR_TABLE = ['W', 'U', 'V', 'G', 'R', 'B'].freeze

      RTT = DiceTable::SaiFicSkillTable.new([
        ['白', ['白竜', '僧侶', '格闘家', '斧使い', '剣士', '槍士', '歩兵', '弓兵', '砲兵', '天使', '軍神']],
        ['青', ['水竜', '魚', '魚人', 'イカ', '蟹', '探偵', '海賊', '魔術師', '使い魔', '雲', '水精霊']],
        ['緑', ['緑竜', 'ワーム', '鳥人', '鳥', '獣', '獣人', 'エルフ', '妖精', '昆虫', '植物', '森精霊']],
        ['金', ['金竜', '宝石', '岩石', '鋼', '錬金術師', '魔法生物', 'ドワーフ', '機械', '運命', '女神', '土精霊']],
        ['赤', ['火竜', '竜人', '恐竜', '戦車', '蛮族', '小鬼', '大鬼', '巨人', '雷', '炎', '火精霊']],
        ['黒', ['黒竜', '闇騎士', '怪物', '忍者', '妖怪', '蝙蝠', '吸血鬼', '不死者', '幽霊', '悪魔', '邪神']],
      ], rtt: "RM", rtt_format: "ランダムモンスター選択(%<category_dice>d,%<row_dice>d) ＞ %<text>s", s_format: "%<category_name>sの%<row_dice>d：%<skill_name>s")

      def get_monster(command)
        m = command.match(/^CM(\w)(\d+)$/i)
        return nil unless m

        cat = COLOR_TABLE.index(m[1])
        row_dice = m[2].to_i
        return nil unless cat
        return nil unless row_dice.between?(2, 12)

        skill = RTT.categories[cat].skills[row_dice - 2]
        return "モンスター選択 ＞ #{skill}"
      end

      TABLES = {
        "BFT" => DiceTable::Table.new(
          "バトルフィールド表",
          "1D6",
          [
            "ハイ・アンティ/戦闘フェイズの終了時、勝者は通常習得できるモンスターカード一つに加えて、もう一つ敗者からモンスターカードを選んで手に入れることができる。//通常よりも多くのカードを賭けの対象にするルール。",
            "バーニング/ラウンドの終了時、すべてのキャラクターは【LP】現在値を3点失う。//マグマの近くや極寒の地など体力を削られるような過酷な環境で行われるルール。",
            "ノーマル/特に影響なし。//通常のルール。",
            "ハード/すべてのキャラクターの判定にプラス1の修正を加える。また、ラウンド終了時にすべてのキャラクターはモンスターカードを一つ選んで破壊状態（ルールブックP187参照）にしなければならない。//風の強い場所や水中など、カードを扱いにくい環境でのルール。",
            "スピード/モンスターカードのリスクが1高いものとして扱われる。また、判定に失敗した場合、速度から振り落とされて1D6のダメージを受ける。//バイクやローラーボードなどを使って行われる高速カードバトルルール。",
            "デスルール/戦闘フェイズでも死亡判定が発声する。また、戦闘不能になったキャラクターは即座に死亡判定を行う。ただし、攻撃を行った側がデスルールを使用しないことを選択すれば、死亡判定は発生しない。//モンスターによって実際のダメージを与える、死の危険性があるルール。"
          ]
        ),
        "CDT" => DiceTable::Table.new(
          "崩壊運命表",
          "1D6",
          [
            "レジェンドカードがあなたを崩壊する大地に呼び寄せた。暴虐な振る舞いをするダークランカーを倒すことをレジェンドカードは望んでいる。",
            "あなたはひょんなことから人を助けた。すると、あなたはいつの間にか救世主と呼ばれる存在になっていた、救世主であるあなたに人々は懇願する。ダークランカーを倒してくれと。",
            "あなたの住むところはダークランカーの力が及ばない楽園であった。しかし、楽園はダークランカー一味の襲撃にあい、あなただけが生き残ってしまった。楽園を出たあなたは戦いを決意する。",
            "世の中は変わった。だが、愛する人（もしくは愛する物や家族）は健在だ。あなたは愛する人を護るためにも、ダークランカーを倒すべく動き始めた。",
            "あなたはこの世界が好きだ。それはどんな理由でもよい。しかし、ダークランカーが持つダークカードはこの世界を壊す。ならば、倒してこの世界を守らねばならない。",
            "崩壊していく大地。泣き叫ぶ人々の声。あなたはこの状況を作ったのが、あなたの身内であると知る。ダークカードの手から身内を救うためにも、あなたはカードを手にとった。"
          ]
        ),
        "CST" => DiceTable::Table.new(
          "街中場所表",
          "1D6",
          [
            "カードショップ/ソウルカードを遊ぶ者たちが集まる場所。プレイスペースもあれば、カードの販売もしている。",
            "ビル街/ビルが立ち並ぶ街。ビジネスマンが忙しなく動き、チェーン店が多く見られる。",
            "駅前/人が集まる駅前。電車から降りてくる人は多く、今日も人と人がすれ違う。",
            "食事処/レストランから大衆食堂、喫茶店やバーなど、食事は人の活力であり、カードランカーにも元気は必要だ。",
            "道路/長く広い道路。車と人が通過していく場所だが、時おりトラブルを抱えたカードランカー同士が戦っている。",
            "プール/都会にあるプール。都会の生活に疲れた人々が集まる場所。時おり、ソウルカードの戦いも見られる。"
          ]
        ),
        "DT" => DiceTable::Table.new(
          "運命表",
          "1D6",
          [
            "あなたが欲しているカードはダークランカーが持っているかもしれないという情報を掴んだ。ダークランカーを倒し、アンティルールでカードを手に入れなければならない。",
            "ダークランカーとなった人物とあなたはカード仲間であったが、ある日見たその人物はダークカードの力にとり憑かれて豹変していた。あなたは仲間をカードによって救うため、戦いを決意した。",
            "ダークランカーはあなたの仲間や身内、大切なモノを傷つけた（壊した）。あなたの大切なものを傷つけたダークランカー、許しはしない。",
            "あなたの持つレジェンドカードが、ダークランカーもしくは他のレジェンドカードが出現することを察知した。レジェンドカードに導かれるまま、キミはダークランカー（レジェンドカード）を探し始めた。",
            "カードランカーの組織やソウルカードの安定を願う人からそのダークランカーを倒すように依頼を受けた、あなたはその仕事を受ける価値があると思った。そう思った理由は報酬でもいいし、あなたの流儀でもよい。",
            "ダークランカーとあなたは偶然にも出会ってしまった。ダークランカーは危険な存在だ。見てしまった以上、放っておくわけにはいかない。"
          ]
        ),
        "GDT" => DiceTable::Table.new(
          "学園運命表",
          "1D6",
          [
            "あなたが過ごしているクラスや寮、部活が潰されそうになった。その裏にはダークランカーの影響があるらしい。",
            "学園の偉い人から、カードランカーであるあなたに調査依頼が入った。どうやらダークランカーが学園に干渉しているとのこと。",
            "学園内のカードが奪われた。ダークランカーの影響だろう。大切にされていたカードを取り戻すために、あなたは立ち上がった。",
            "学内に邪悪な影響を受けたカードが入り込んでいた。おそらく、ダークランカーの仕業に違いない。",
            "ダークランカーによって被害を受けた生徒があなたに相談してきた。あなたはその生徒のためにもダークランカーの調査に乗り出した。",
            "ダークランカーの影響を受け、授業や部活動はまともにできなくなってしまった。あなたは元の学校生活を再開させるためにも、調査を始めた。"
          ]
        ),
        "OST" => DiceTable::Table.new(
          "郊外場所表",
          "1D6",
          [
            "カードショップ/ソウルカードを遊ぶ者たちが集まる場所。少し治安と客層が悪いが、賞金稼ぎも集まる。",
            "荒野/動植物も少なく、ピリピリとした雰囲気のある場所。",
            "遺跡/古代の遺跡。レジェンドカードやモンスターカードはこうした場所に発生したり、隠されていたりすることが多い。",
            "平原/どこまでも続く平原。動物も温厚であり、生い茂る草花が柔らかな印象を与える場所だ。",
            "山岳/険しい道が続く山。カードの精霊たちが生息していることもあるが、カード山賊団には気をつけねばならない。",
            "海川/海や川。山と同じくカードの精霊たちが住んでいる場所だ。安らげる場所でもあり、休憩している人がソウルカードをしている。"
          ]
        ),
        "GST" => DiceTable::Table.new(
          "学園場所表",
          "1D6",
          [
            "購買/学生にとっては学園内で唯一買い物ができる場所。パンの他に、カードパックが売っている。",
            "グラウンド／体育館/運動するのに適した広い空間だが、同時にソウルカードをやるのにもうってつけの場所である。",
            "屋上/校舎の屋上は一部の生徒には人気のスポットだ。今日も強い風が彼らを迎えている。",
            "教室/日が昇っている間は、学生たちの声で賑やかな場所。夕暮れからは少し物哀しく、寂しい。",
            "校舎裏/学校の中でも珍しく人目につかない場所。不良たちがソウルカードをやっている姿が見られる。",
            "部活棟/部活をやる者のために用意された場所。しかし、サボってソウルカードをやっているところも。"
          ]
        ),
        "ST" => DiceTable::Table.new(
          "場所表",
          "1D6",
          [
            "カード系/ショップや大会の会場など、ソウルカードに関係がある場所。カードランカーたちも集まってくる。",
            "自然/公園や山など、自然の息吹が感じられる場所。耳を澄ませばカードの声も聞こえるかもしれない。",
            "神秘/古代の施設や、神社・教会などの神秘的な場所。レジェンドカードが隠されているかもしれない。",
            "安息/自宅など、安らげる空間。そこはあなたが安らげる場所であり、思い出の地なのかもしれない。",
            "街中/人々が住む街中。何気なく落ちているカードの中には、価値があるものもあるかも。",
            "水辺/プールや海岸など、水が近くに存在する場所。ひとまず、ここでひと息つけそうだ。"
          ]
        ),
        "TDT" => DiceTable::Table.new(
          "大会運命表",
          "1D6",
          [
            "あなたは友人と共に大会に出場した。しかし、友人はダークランカーによって倒されてしまった。",
            "あなたは大会の商品を狙い、大会に出場した。だが、ダークランカーもそれを狙っているらしい。",
            "あなたは大会の運営者から、大会に関わっているダークランカーの撃破を依頼された。",
            "あなたはカードの導くままに、大会に関わってくるダークランカーの出現を察知した。",
            "あなたは大会の一選手として戦っていた。だが、謎の刺客によって襲われた。きっとダークランカーの仕業に違いない。",
            "あなたは大会に出場し、優勝候補と言われているカードランカーだ。だが、そんなキミをダークランカーは襲った。"
          ]
        ),
        "WT" => DiceTable::Table.new(
          "変調表",
          "1D6",
          [
            "猛毒/ラウンド終了時に【LP】の現在値を3点失う。また【LP】の現在値を回復できない。",
            "炎上/ラウンド終了時に、モンスターカードを一つ選び破壊状態にしなければならない。既に破壊状態になっているものは選べない。",
            "妨害/攻撃判定にマイナス2の修正を受ける。",
            "捕縛/ブロック判定にマイナス2の修正を受ける。",
            "召喚制限/「タイプ：補助」のモンスターカードを使用できない。",
            "暗闇/「タイプ：支援」のモンスターカードを使用できない。"
          ]
        ),
      }.freeze
      register_prefix(RTT.prefixes, 'CM.*', TABLES.keys)
    end
  end
end
