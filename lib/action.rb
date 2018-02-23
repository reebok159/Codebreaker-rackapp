require 'codebreaker'
require 'yaml'
require 'yaml/store'

class Action
  def initialize(request)
    @request = request
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
    init_game
    Rack::Response.new do |response|
      response.redirect('/play')
    end
  end

  def make_guess
    Rack::Response.new do |response|
      response.redirect('/') and next unless is_playing?
      clear_temp
      input_guess = @params['guess'].to_s
      res = check_guess(input_guess)
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

  def check_guess(guess)
    return unless guess.size == 4
    @game.make_guess(guess)
  end

  def finish_game(res, response)
    @session['playing'] = false
    save_result(res)
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

  def init_game
    game = Codebreaker::Game.new
    game.start
    clear_temp
    @session['game_obj'] = game
    @session['last_guesses'] = []
    @session['playing'] = true
    name = @params['player_name']
    @session['player_name'] = name.to_s.empty? ? 'stranger' : name
  end

  def is_playing?
    @session['playing'] || false
  end

  def clear_temp
    @session['result'] = ''
    @session['hint'] = ''
  end

  def save_result(res)
    return if res == :lose
    data = { name: @session['player_name'], code: @game.get_secret_code }
    store = YAML::Store.new "results.yml"
    store.transaction do
      store["results"] = store["results"].to_a.unshift(data)
    end
  end

  def load_results
    parsed = YAML.load_file("results.yml")
    parsed['results']
  rescue Exception => e
  end

  def render_view(page)
    Rack::Response.new(render("#{page}.html.erb"))
  end

  def render(template)
    path = File.expand_path("../views/#{template}", __FILE__)
    ERB.new(File.read(path)).result(binding)
  end
end
