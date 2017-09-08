#
# コンテナ管理用クラス
#

require 'bundler'
Bundler.require

require 'docker'
require 'json'
require 'securerandom'
require 'directory_manager'
require 'logger'

class ExecutionContainer
  PARENT_DIRECTORY_OF_WORKSPACE_DIR = "/tmp/"
  SOURCE_FILE_NAME                  = 'main'
  INPUT_FILE_NAME                   = 'input'
  EXECUTION_TIME_FILE_NAME          = 'time.txt'

  # 初期化メソッド
  # @param [Hash] input_data  実行対象のデータ
  # @option input_data [String] language        言語
  # @option input_data [String] source_code     ソースコード
  # @option input_data [String] standard_input  標準入力
  def initialize(input_data)
    @language              = input_data[:language]
    @source_code           = input_data[:source_code]
    @standard_input        = input_data[:standard_input]
    @identification_number = SecureRandom.hex(8)
    @working_dirname       = "workspace_#{@identification_number}"
  end
  
  # プログラム実行メソッド
  # == 実行順序
  #   - ディレクトリ・ファイル作成
  #   - コンテナ実行
  #   - 結果取得
  #   - ディレクトリ・ファイル削除
  #   - jsonの作成・返却
  # @return [String] json形式の実行結果 
  def execute
    directory_manager = make_working_directory
    begin
      make_source_file(directory_manager)
      make_input_file(directory_manager)
      result = execute_container(make_container)
      execution_time = get_execution_time(directory_manager)
    rescue => e
      raise "error: execution_docker(detail: #{e})"
    ensure
      directory_manager.delete_directory
    end
    make_result_json(result, execution_time)
  end

  private 

  # コンテナ作成メソッド
  # @return [Docker::Container] コンテナクラスのインスタンス
  def make_container
    Docker::Container.create(
      name: "coderunner_#{@identification_number}",
      Image: 'coderunner-ubuntu-env',
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

  # コンテナ実行メソッド
  # @return [Hash] コンテナの実行結果
  def execute_container(container)
    begin
      container.start
      container_cmd = "cd /workspace && /usr/bin/time -q -f \"%e\" -o /workspace/#{EXECUTION_TIME_FILE_NAME} timeout 3 #{make_execution_command} < #{INPUT_FILE_NAME}"  
      result = container.exec(['bash', '-c', container_cmd])
    rescue => e
      raise e
    ensure 
      container.stop
      container.delete(force: true) 
    end

    return result
  end

  # ワーキングディレクトリ作成メソッド
  # @return [DirectoryManager] ワーキングディレクトリを管理するDirectoryManagerクラスのインスタンス
  def make_working_directory
    working_dir_path = "#{PARENT_DIRECTORY_OF_WORKSPACE_DIR}#{@working_dirname}"
    directory_manager = DirectoryManager.new(working_dir_path)
    directory_manager.make_directory(0777)
    return directory_manager
  end

  # ソースファイル作成メソッド
  def make_source_file(directory_manager)
    directory_manager.write_file(*make_source_file_data)
  end

  # 入力ファイル作成メソッド
  def make_input_file(directory_manager)
    directory_manager.write_file(*make_input_file_data)
  end

  # ソースファイルデータ作成メソッド
  # @return [Array] ファイル名とソースコードを返却
  def make_source_file_data
    case @language
    when 'ruby'
      ["#{SOURCE_FILE_NAME}.rb", @source_code]
    when 'python'
      ["#{SOURCE_FILE_NAME}.py", @source_code]
    when 'c'
      ["#{SOURCE_FILE_NAME}.c", @source_code]
    end
  end

  # 入力ファイルデータ作成メソッド
  # @return [Array] ファイル名と入力値を返却
  def make_input_file_data
    [INPUT_FILE_NAME, @standard_input]
  end

  # プログラム実行コマンド作成メソッド
  # @return [String] コンテナ内で実行するプログラム実行コマンドを返却
  def make_execution_command
    case @language
    when 'ruby'
      "ruby #{SOURCE_FILE_NAME}.rb"
    when 'python'
      "python #{SOURCE_FILE_NAME}.py"
    when 'c'
      "cc -Wall -o #{SOURCE_FILE_NAME} #{SOURCE_FILE_NAME}.c && ./#{SOURCE_FILE_NAME}"
    end
  end

  # 実行時間取得メソッド
  # @return [String] 実行時間
  def get_execution_time(directory_manager)
    directory_manager.read_file(EXECUTION_TIME_FILE_NAME)
  end

  # json作成メソッド
  # @result [Hash] 実行結果
  def make_result_json(container_result, execution_time)
    stdout_str = container_result[0].join('').force_encoding('UTF-8') 
    stderr_str = container_result[1].join('').force_encoding('UTF-8') 
    exit_code = container_result[2]
    {stdout: stdout_str, stderr: stderr_str, time: execution_time, exit_code: exit_code}.to_json
  end
end