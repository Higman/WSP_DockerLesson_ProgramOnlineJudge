#
# ディレクトリ管理用クラス
#

require 'open3'
require 'fileutils'

class DirectoryManager
  # 初期化メソッド
  # @param [String] path  管理したいディレクトリのパス
  def initialize(path)
    path = $1 if path =~ %r{\A(.+)/\z}
    @path = path
    @directory_name   = path.match(%r{/?([^/]+)\z})[1]
    @parent_directory = path.match(%r{\A(.*)/}) ? $1 : "./"
    all_freeze
  end

  # ファイル書き込みメソッド
  # @param [String] file_name  ファイル名
  # @param [String] content    書き込みたいファイルの内容
  def write_file(file_name, content)
    make_directory
    file_path = "#{@path}/#{file_name}"
    File.write(file_path, content)
  end

  # ファイル読み込みメソッド
  # @param [String] file_name ファイル名
  def read_file(file_name)
    file_path = "#{@path}/#{file_name}"
    File.read(file_path)
  end 

  # ディレクトリ作成するメソッド
  def make_directory(dir_mode = 0775)
    FileUtils.mkdir_p(@path, mode: dir_mode)
  end

  # ディレクトリ削除メソッド
  def delete_directory
    FileUtils.rm_r(@path, :secure => true)
  end

  private 

  # インスタンス変数の固定化メソッド
  def all_freeze
    @path.freeze
    @directory_name.freeze
    @parent_directory.freeze
  end
end