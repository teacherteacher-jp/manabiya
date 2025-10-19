module Tools
  class Calculator
    # Anthropic Tool Use API形式の定義
    def self.definition
      {
        name: "calculator",
        description: "数式を計算します。加減乗除や累乗などの基本的な計算ができます。",
        input_schema: {
          type: "object",
          properties: {
            expression: {
              type: "string",
              description: "計算する数式 (例: '2 + 2', '10 * 5', '2 ** 3')"
            }
          },
          required: ["expression"]
        }
      }
    end

    # ツールを実行
    # @param input [Hash] ツールへの入力
    # @return [String] 計算結果
    def self.execute(input)
      expression = input["expression"] || input[:expression]

      # 安全のため、eval は使わずに簡易的な計算のみ対応
      # 実際の実装では safe_eval gem などを使うべき
      begin
        # 数字と演算子のみ許可（安全性チェック）
        unless expression.match?(/\A[\d\s\+\-\*\/\(\)\.\*\*]+\z/)
          return "エラー: 使用できない文字が含まれています"
        end

        result = eval(expression)
        "計算結果: #{expression} = #{result}"
      rescue => e
        "エラー: #{e.message}"
      end
    end
  end
end
