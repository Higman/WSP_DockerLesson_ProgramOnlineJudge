$: << "#{File.dirname(__FILE__)}/lib/"

require 'bundler'
Bundler.require

require 'sinatra'
require 'sinatra/reloader' if development?
require 'input_data_manager'
require 'execution_container'
require 'logger'
logger = Logger.new(STDOUT)

get '/' do
  slim :index
end

post '/api/run' do
  input_data_manager  = InputDataManager.new(params)
  logger.debug(input_data_manager)
  execution_container = ExecutionContainer.new(input_data_manager.get_all)
  content_type(:json)
  execution_container.execute
end