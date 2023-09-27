# frozen_string_literal: true

module BCDice
  module GameSystem
    class NarratoGraph < Base
      # ゲームシステムの識別子
      ID = "NarratoGraph"

      # ゲームシステム名
      NAME = "東方Project二次創作TRPG 幻想ナラトグラフ"

      # ゲームシステム名の読みがな
      SORT_KEY = "けんそうならとくらふ"

      HELP_MESSAGE = <<~TEXT
      ・行為判定 dNG>=t
      　指定された数D6を振り、ダイスごとに成功・失敗の判定を行います。
      　　d：ダイス数 省略可(省略時2)
      　　t：目標値 省略可(省略時4)
      　例：NG 3NG NG>=3 4NG>=5
      ・移動ロール dMV±m
      　指定された数D6を振り、ダイスごとに移動量やハプニングの判定を行います。
      TEXT

      def eval_game_system_specific_command(command)
        return judgeRoll(command) || moveRoll(command) || roll_tables(command, TABLES)
      end

      def judgeRoll(command)
        return nil unless /^((\d+)?NG)((>(=))?([+\-\d]*))?$/i =~ command

        diceCount = (Regexp.last_match(2).nil? ? "2" : Regexp.last_match(2)).to_i
        targetText = (Regexp.last_match(6).nil? || Regexp.last_match(6) == "" ? "4" : Regexp.last_match(6))
        signOfInequality = (Regexp.last_match(4).nil? ? ">=" : Regexp.last_match(4))
  
        target = targetText.to_i

        specialNum = 6
        specialNum = specialNum.to_i
  
        commandText = "#{diceCount}NG#{signOfInequality}#{target}"

        diceList = @randomizer.roll_barabara(diceCount, 6).sort
        diceText = diceList.join(",")
  
        message = "(#{commandText}) ＞ [#{diceText}] ＞ "
        
        if /^(1)+$/i =~ diceList.join("") then
          message += "ファンブル"
        else
          if diceList.length == 1
          then
            dice = diceList.first
            result = check_success(dice, target, signOfInequality, specialNum)
            message += "#{dice}:#{result}"
          else
            texts = []
            rests = diceList.clone
            diceList.each_with_index do |pickup_dice, index|
              dice = rests[0].to_i
              result = check_success(dice, target, signOfInequality, specialNum)

              texts << "　#{dice}を選択した場合:#{result}"
              rests.delete_at(0)
            end
            texts.uniq!
            message += "\n" + texts.join("\n")
          end
        end
        return message  
      end

      def check_success(dice_n, target, signOfInequality, special_n)
        return "スペシャル" if dice_n >= special_n

        target_num = target.to_i
        cmp_op = Normalize.comparison_operator(signOfInequality)

        if dice_n.send(cmp_op, target_num)
          "成功"
        else
          "失敗"
        end
      end
      
      def moveRoll(command)
        return nil unless /^((\d+)?MV)([+\-\d]+)?$/i =~ command
        diceCount = Regexp.last_match(2).nil? ? "1" : Regexp.last_match(2)
        diceCount = diceCount.to_i
        diceList = @randomizer.roll_barabara(diceCount, 6).sort

        modifyText = Regexp.last_match(3)
        modify = ArithmeticEvaluator.eval(modifyText)

        commandText = "#{diceCount}MV#{modifyText}"
        diceText = diceList.join(",")

        message = "(#{commandText}) ＞ [#{diceText}] ＞ "

        if diceList.length == 1
          dice = diceList.first
          result = check_move(dice,modify)
          message += "#{result}"
        else
          texts = []
          lookeddice = []
          rests = diceList.clone
          diceList.each_with_index do |pickup_dice, index|
            dice = rests[0].to_i
            unless lookeddice.include?(dice) then
            result = check_move(dice,modify)
            texts << "　#{dice}を選択した場合:#{result}"
            lookeddice << dice
            end
            rests.delete_at(0)
          end
          message += "\n" + texts.join("\n")
        end
        return message
      end

      def check_move(dice,modify)
        if dice == 6
          return "ハプニング"
        else
          return dice + modify
        end
      end

      TABLES = {
        "WT" => DiceTable::Table.new(
          "変調表",
          "1D6",
          [
            "だるい",
            "スランプ",
            "二日酔い",
            "怪我",
            "不機嫌",
            "疲れた"
          ]
        ),
        "SPT" => DiceTable::D66Table.new(
          "場所表",
          D66SortType::ASC,
          {
            11 => "人間の里",
            12 => "命蓮寺",
            13 => "香霖堂",
            14 => "マヨヒガ",
            15 => "間欠泉地下センター",
            16 => "太陽の畑",
            22 => "守屋神社",
            23 => "玄武の沢",
            24 => "大蝦墓の池",
            25 => "妖怪の樹海",
            26 => "九天の滝",
            33 => "紅魔館",
            34 => "霧の湖",
            35 => "霧雨魔法店",
            36 => "魔法の森",
            44 => "白玉楼",
            45 => "旧地獄街道",
            46 => "地霊殿",
            55 => "永遠亭",
            56 => "迷いの竹林",
            66 => "博麗神社"
          }
        ),
        "IDT" => DiceTable::D66Table.new(
          "個性スキル",
          D66SortType::ASC,
          {
            11 => "真面目 (ルルブp.189)",
            12 => "馬鹿 (ルルブp.189)",
            13 => "用意周到 (ルルブp.189)",
            14 => "瀟洒 (ルルブp.190)",
            15 => "活発 (ルルブp.190)",
            16 => "熱中 (ルルブp.190)",
            22 => "胡乱 (ルルブp.190)",
            23 => "快適な拠点 (ルルブp.190)",
            24 => "怠け者 (ルルブp.190)",
            25 => "人気者 (ルルブp.191)",
            26 => "寂しがり屋 (ルルブp.191)",
            33 => "インドア派 (ルルブp.191)",
            34 => "アウトドア派 (ルルブp.191)",
            35 => "ご執心 (ルルブp.191)",
            36 => "能天気 (ルルブp.191)",
            44 => "カリスマ (ルルブp.192)",
            45 => "我儘 (ルルブp.192)",
            46 => "不夜城 (ルルブp.192)",
            55 => "信仰 (ルルブp.192)",
            56 => "赤貧 (ルルブp.192)",
            66 => "直感 (ルルブp.192)"
          }
        )

      }.freeze

      register_prefix('\d*NG', '\d*MV', TABLES.keys)
    end
  end
end
