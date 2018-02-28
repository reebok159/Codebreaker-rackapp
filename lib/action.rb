require 'codebreaker'
require_relative 'services/file_service'
require_relative 'services/game_service'

class Action
  def initialize(request)
    @request = request
    @game_service = GameService.new(@request)
    @file_service = FileService.new(@request)
    @session = @request.session
    @params = @request.params
    @game = @session['game_obj']
  end

  def show_index
    render_view('index')
  end

  def show_play
    page = is_playing? ? "play" : "index"
    render_view(page)
  end

  def show_result
    return render_view('result') unless @game&.get_secret_code.nil?
    Rack::Response.new do |response|
      response.redirect('/')
    end
  end

  def start_game
    @game_service.init_game
    Rack::Response.new do |response|
      response.redirect('/play')
    end
  end

  def make_guess
    Rack::Response.new do |response|
      response.redirect('/') and next unless is_playing?
      @game_service.clear_result_and_hint
      input_guess = @params['guess'].to_s
      res = @game_service.check_guess(input_guess)
      finish_game(res, response) and next if res == :lose || res == '++++'
      save_last_guess(res, input_guess)
      return_to_game(res, response)
    end
  end

  def get_hint
    Rack::Response.new do |response|
      response.redirect('/') and next unless is_playing?
      @session['hint'] =  @game.get_hint
      response.redirect('/play')
    end
  end

  private

  def finish_game(res, response)
    @session['playing'] = false
    @file_service.save_result(res)
    res = res == '++++' ? 'You win' : 'You lose'
    @session['result'] = res
    response.redirect('/result')
  end

  def save_last_guess(res, input_guess)
    return if input_guess.to_s.empty?
    @session['last_guesses'] << "[#{res}] - #{input_guess}"
  end

  def return_to_game(res, response)
    @session['result'] = res
    response.redirect('/play')
  end

  def is_playing?
    @session['playing'] || false
  end

  def render_view(page)
    Rack::Response.new(render("#{page}.html.erb"))
  end

  def render(template)
    path = File.expand_path("../views/#{template}", __FILE__)
    ERB.new(File.read(path)).result(binding)
  end
end
