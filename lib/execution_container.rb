#
# コンテナ管理用クラス
#

require 'bundler'
Bundler.require
require 'docker'
require 'json'
require 'securerandom'
require 'directory_management'

class ExecutionContainer 
  # 初期化メソッド
  # @param [Hash] input_data  実行対象のデータ
  # @option input_data [String] language        言語
  # @option input_data [String] source_code     ソースコード
  # @option input_data [String] standard_input  標準入力
  def initialize(input_data)
    @language       = input_data[:language]
    @source_code    = input_data[:source_code]
    @standard_input = input_data[:standard_input]
    @identification_number = SecureRandom.hex(8)
  end

  def exec

  end

  private 

  def make_container

  end


end