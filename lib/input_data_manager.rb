#
# フォーム値管理クラス
#

class InputDataManager
  include Enumerable
  
  # 初期化メソッド
  def initialize(params)
    @language        = params[:language]
    @source_code     = params[:source_code]
    @standard_inputs = params[:input]
  end

  def get_all
    {language: @language, source_code: @source_code, input: @standard_inputs}
  end

  # フォーム値取得メソッド
  def each
    @standard_inputs.each do |standard_input| 
      yield [@language, @source_code, standard_input]
    end
  end
end