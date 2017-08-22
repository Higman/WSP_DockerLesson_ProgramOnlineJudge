require 'bundler'
Bundler.require

require 'sinatra'
require 'sinatra/reloader'
require 'docker'
require 'json'
require 'logger'
require 'open3'
require 'fileutils'

logger = Logger.new(STDOUT)

get '/' do
  slim :index
end

post '/api/run' do
  language   = params[:language]
  source_code = params[:source_code]
  input      = params[:input]
  exec_time  = Time.now.to_f  # 実行時間

  source_filename  = "main"      # ソースファイル名
  input_filename  = "input"     # 入力ファイル名
  workdir_dirname = "workspace_#{exec_time}" # 作業ディレクトリ名
  case language
  when 'ruby'
    source_filename += '.rb'
    exec_cmd = "ruby #{source_filename}"
  when 'python'
    source_filename += '.py'
    exec_cmd = "python #{source_filename}"
  when 'c'
    filename_id = source_filename  # .cなしの文字列を保持
    source_filename += '.c'
    exec_cmd  = "cc -Wall -o #{filename_id} #{source_filename} && ./#{filename_id}"
  end

  ## コンテナの作成
  logger.info("Creating Container")
  container = Docker::Container.create(
    name: "test_#{exec_time}", 
    Image: 'ubuntu-dev', 
    WorkingDir: '/workspace', 
    Memory: 512 * 1024**2, 
    MemorySwap: 512 * 1024**2, 
    PidsLimit: 30,
    HostConfig: { 
      Binds:  ["/tmp/#{workdir_dirname}:/workspace"]
    },
    Tty: true
  )
  logger.info("Created Container id: #{container.id}")
  
  ## コンテナへソースコードのコピー
  # 作業ディレクトリの作成
  Open3.popen3("mkdir /tmp/#{workdir_dirname} && chmod 777 /tmp/#{workdir_dirname}") do |i, o, e, w| 
    i.close
    o.each do |line| p line end
    e.each do |line| p line end
  end
  # ソースファイルの作成
  File.open("/tmp/#{workdir_dirname}/#{source_filename}", "w") do |f|
    source_code.split('\n').each do |line|
      f.puts(line)
    end
  end
  # 入力ファイルの作成
  File.open("/tmp/#{workdir_dirname}/#{input_filename}", "w") do |f|
    input.split('\n').each do |line|
      f.puts(line)
    end
  end

  # コンテナ実行
  container.start
  container_cmd = "cd /workspace && /usr/bin/time -q -f \"%e\" -o /workspace/time.txt timeout 3 #{exec_cmd} < #{input_filename}"  # コマンド
  res = container.exec(['bash', '-c', container_cmd])
  container.stop                # コンテナの停止
  container.delete(force: true) # コンテナの削除

  # 実行時間の取得
  proc_time = ""
  File.open("/tmp/#{workdir_dirname}/time.txt", "r") do |f|
    proc_time = f.gets + " [s]"
  end

  # 事後処理
  FileUtils.rm_r("/tmp/#{workdir_dirname}") # 作業ディレクトリの削除
  
  # 返却
  content_type :json
  return_params = {stdout: res[0].join(''), stderr: res[1].join(''), time: proc_time,exit_code: res[2]}
  return_params.to_json
end