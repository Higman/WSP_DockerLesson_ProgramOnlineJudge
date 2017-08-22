// エディタ部分の初期化
// ace editorという外部ライブラリを呼出し
var aceEditor = ace.edit("source_code");

aceEditor.setOptions({
  enableBasicAutocompletion: true,
  enableLiveAutocompletion: true,
  enableSnippets: true,
});

// Ctrl+Enterでrun_buttonを押下判定
$('#run_button').on("click", function(event) {
  runCode();
});

aceEditor.commands.addCommand({
  bindKey: {win: "Ctrl-Enter", mac: "Ctrl-Enter"},
  exec: runCode,
});

// ace editorのシンタックスの設定
function setEditorLanguage(language) {
  var languageToMode = {
    ruby: 'ruby',
    python: 'python',
    c: 'c_cpp',
  };
  var mode = languageToMode[language];
  aceEditor.getSession().setMode("ace/mode/" + mode);
}

$('#language').val('ruby');
setEditorLanguage('ruby');
$('#language').on("change", function(event){
  setEditorLanguage(this.value);
});