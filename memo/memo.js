// 必要なモジュールの読み込み
var express = require('express');
var app = express();
var bodyParser = require('body-parser');
var child_process = require('child_process');
var fs = require('fs');

//
app.use(express.static('public'));
app.use(bodyParser.urlencoded({extended: false}));

//  ---- ここまでおまじない ----

// `localhost:3000/api/run` にポストしたとき
// 
// sinatraだとpostメソッド
app.post('/api/run', function(req, res){
  var language = req.body.language;
  // sinatraだと
  // language = params[:language]
  var source_code = req.body.source_code;
  var input = req.body.input;

  // postされたフォームの内容によって処理を分岐
  // 言語によるコマンド/ファイル名の切り替え
  var filename, execCmd;
  if ( language === 'ruby' ) {
    filename = 'main.rb';
    execCmd = 'ruby main.rb'
  } else if ( language === 'python' ) {
    filename = 'main.py';
    execCmd = 'python main.py';
  } else if ( language === 'c' ) {
    filename = 'main.c';
    execCmd = 'cc -Wall -o main main.c && ./main';
  }

  // 実行用コンテナの作成
  var dockerCmd =  'docker create -i ' +
    '--net none ' +
    '--cpuset-cpus 0 ' +
    '--memory 512m --memory-swap 512m ' +
    '--ulimit nproc=10:10 ' +
    '--ulimit fsize=1000000 ' +
    '-w /workspace ' +
    'ubuntu-dev ' +
    // 以下Docker内でのコマンド
    '/usr/bin/time -q -f "%e" -o /time.txt ' +  // 時間計測  timeコマンド
    'timeout 3 ' +  // timeoutオプション    無限ループ対策
    'su nobody -s /bin/bash -c"' +   // ユーザ指定
    execCmd +
    '"';

  console.log("Running: " + dockerCmd);
  var containerId = child_process.execSync(dockerCmd).toString().substr(0, 12); // dockerコンテナの起動
  console.log("ContainerId: " + containerId);

  // コンテナへソースコードのコピー
  child_process.execSync('rm -rf /tmp/workspace && mkdir /tmp/workspace && chmod 777 /tmp/workspace');
  fs.writeFileSync('/tmp/workspace/' + filename, source_code);
  dockerCmd = 'docker cp /tmp/workspace ' + containerId + ':/';  // ホスト内のディレクトリをコンテナ内のディレクトリにコピー
  child_process.execSync(dockerCmd);

  // child_process.exec() と child_process.execSync()
  // 前者は同期（処理が終わるまで待つ）
  // 後者は非同期
  // 
  // exec 
  //  第一引数:
  //  第二引数: オプション
  //  第三引数: callback関数 
  // 
  // コンテナの起動
  dockerCmd = 'docker start -i ' + containerId
  console.log('Running: ' + dockerCmd);
  var child = child_process.exec(dockerCmd, {}, function(err, stdout, stderr) {
    dockerCmd = 'docker cp ' + containerId + ":/time.txt /tmp/";
    console.log("Running: " + dockerCmd);
    child_process.execSync(dockerCmd);
    var time = fs.readFileSync('/tmp/time.txt').toString();

    // コンテナ削除
    dockerCmd = 'docker rm ' + containerId;
    console.log("Running: " + dockerCmd);
    child_process.execSync(dockerCmd);

    console.log('Result: ', err, stdout, stderr);
    res.send({
      stdout: stdout,
      stderr: stderr,
      exit_code: err && err.code || 0,
      time: time
    });
  });
  child.stdin.write(input);
  child.stdin.end();
});

app.listen(3000, function(){
  console.log('listening on port 3000');
});

// sinatraだと
// get '/' do
//  p "listening on port 3000"
// end