module Discord
  # Discord添付ファイルのダウンロードと処理を担当するサービスクラス
  class AttachmentDownloader
    # 添付ファイルのテキスト内容をダウンロード
    # @param url [String] ファイルのURL
    # @param filename [String, nil] ファイル名（ログ出力用）
    # @return [String, nil] ファイルの内容（バイナリの場合やエラー時はnil）
    def self.download_text_content(url, filename: nil)
      require 'faraday'

      response = Faraday.get(url)

      unless response.success?
        Rails.logger.error "Failed to download attachment: #{response.status} #{response.reason_phrase}"
        return nil
      end

      # まず生のバイトデータとして取得
      raw_content = response.body

      # バイナリファイルかチェック（先頭1000バイトを確認）
      sample = raw_content[0...1000] || raw_content
      if binary_content?(sample)
        Rails.logger.info "Skipping binary file: #{filename}"
        return nil
      end

      # テキストファイルとしてUTF-8で解釈
      content = raw_content.force_encoding('UTF-8')

      # 有効なUTF-8でなければ、他のエンコーディングを試す
      unless content.valid_encoding?
        # Shift_JISやEUC-JPなど日本語エンコーディングを試す
        %w[Shift_JIS EUC-JP Windows-31J].each do |encoding|
          begin
            content = raw_content.force_encoding(encoding).encode('UTF-8')
            break if content.valid_encoding?
          rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
            next
          end
        end

        # どれもダメならバイナリとして扱う
        unless content.valid_encoding?
          Rails.logger.info "Could not decode file as text: #{filename}"
          return nil
        end
      end

      # サイズ制限: テキストファイルは一律80KB
      max_size = 80_000

      # サイズが大きすぎる場合は先頭部分のみ返す
      if content.bytesize > max_size
        "#{content[0..max_size]}\n\n... (#{content.bytesize} bytes中#{max_size} bytesまで表示)"
      else
        content
      end
    rescue => e
      Rails.logger.error "Error downloading attachment: #{e.class} - #{e.message}"
      nil
    end

    # バイナリファイルかどうかを判定
    # @param sample [String] ファイルの先頭サンプル（バイナリ）
    # @return [Boolean] バイナリファイルの場合true
    def self.binary_content?(sample)
      # NULLバイト(\x00)が含まれていればバイナリ
      return true if sample.include?("\x00")

      # 制御文字の割合が高ければバイナリ
      control_chars = sample.bytes.count { |b| b < 32 && ![9, 10, 13].include?(b) }
      control_ratio = control_chars.to_f / sample.bytesize
      control_ratio > 0.3
    end
  end
end
