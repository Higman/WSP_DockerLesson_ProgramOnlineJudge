#
# コンテナ管理用クラス
#

require 'bundler'
Bundler.require

require 'docker'
require 'json'
require 'securerandom'
require 'directory_manager'

class ExecutionContainer
  PARENT_DIRECTORY_OF_WORKSPACE_DIR = "/tmp/"

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
    @working_dirname = "workspace_#{exec_time}"
  end

  def exec

  end

  private 

  def make_container
    Docker::Container.create(
      name: "coderunner_#{@identification_number}", 
      Image: 'ubuntu-dev', 
      WorkingDir: '/workspace', 
      Memory: 512 * 1024**2, 
      MemorySwap: 512 * 1024**2, 
      PidsLimit: 30,
      HostConfig: { 
        Binds:  ["/tmp/#{@working_dirname}:/workspace"]
      },
      Tty: true
    )
  end

  def make_working_dir
    working_dir_path = "#{PARENT_DIRECTORY_OF_WORKSPACE_DIR}#{@working_dirname}"
    directory_managemer = 
  end
end