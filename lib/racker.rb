require_relative './action'

class Racker
  def self.call(env)
    new(env).response.finish
  end

  def initialize(env)
    @request = Rack::Request.new(env)
    @action = Action.new(@request)
  end

  def response
    case @request.path
    when '/'            then @action.show_index
    when '/play'        then @action.show_play
    when '/result'      then @action.show_result
    when '/start_game'  then @action.start_game
    when '/make_guess'  then @action.make_guess
    when '/hint'        then @action.get_hint
    else Rack::Response.new('Not Found', 404)
    end
  end
end
