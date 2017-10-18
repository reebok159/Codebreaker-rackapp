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
    when '/' then @action.index
    when '/start_game' then @action.start_game
    when '/make_guess' then @action.make_guess
    when '/game' then @action.game
    when '/hint' then @action.get_hint
    when '/result' then @action.show_result
    else @action.not_found
    end
  end
end
