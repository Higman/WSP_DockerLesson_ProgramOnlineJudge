// ajaxを使ってソースコードをアップロードするやつ
function runCode() {
  $('#run_button').text('実行中').prop('disabled', true);

  var language = $('#language').val();
  var source_code = aceEditor.getValue();
  var input = $('#input').val();

  $.ajax({
    // '/api/run'にデータをぶん投げる設定
    url: '/api/run',
    method: 'POST',
    data: {
      language: language,
      source_code: source_code,
      input: input
    }
  }).done(function(result) {
    // サーバ側で実行終了したときの結果の反映
    
    $('#stdout').text(result.stdout);
    $('#stderr').text(result.stderr);
    $('#time').text(result.time);
    $('#exit_code').text(result.exit_code);
    $('#run_button').text('実行(Ctrl-Enter)').prop('disabled', false);
  }).fail(function(jqXHR, textStatus, errorThrown){
    // サーバ側で実行がコケたときのエラーハンドリング
    alert_str = 'Requiest Failed: ' + jqXHR.status + '\n' +
                'Error Info:      ' + textStatus + '\n' + 
                'Exception Info:  ' + errorThrown;
    alert(alert_str);
    $('#run_button').text('実行(Ctrl-Enter)').prop('disabled', false);
  });
}