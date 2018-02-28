class GameService
  def initialize(request)
    @request = request
    @session = @request.session
    @params = @request.params
    @game = @session['game_obj']
  end

  def init_game
    game = Codebreaker::Game.new
    game.start
    clear_result_and_hint
    @session['game_obj'] = game
    @session['last_guesses'] = []
    @session['playing'] = true
    name = @params['player_name']
    @session['player_name'] = name.to_s.empty? ? 'stranger' : name
  end

  def check_guess(guess)
    return unless guess.size == 4
    @game.make_guess(guess)
  end

  def clear_result_and_hint
    @session['result'] = ''
    @session['hint'] = ''
  end
end
