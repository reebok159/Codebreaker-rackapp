require 'codebreaker'
require 'erb'
require 'pry'
require 'yaml'

class Action
  def initialize(req)
    @request = req
    @game = @request.session['game_obj']
    @last_guesses = @request.session['last_guesses']
    @playing = @request.session['playing']
    @player_name = @request.session['player_name']
  end

  def index
    Rack::Response.new(render('index.html.erb'))
  end

  def start_game
    game = Codebreaker::Game.new
    game.start
    Rack::Response.new do |response|
      @request.session['game_obj'] = game
      @request.session['last_guesses'] = []
      @request.session['playing'] = true
      set_name(@request.params['player_name'])
      clear_cookies(response)
      response.redirect('/game')
    end
  end

  def game
    page = "game"
    page = "index" unless @playing
    Rack::Response.new(render("#{page}.html.erb"))
  end

  def make_guess
    Rack::Response.new do |response|
      response.redirect('/') and next unless @playing
      response.set_cookie('hint', 'none')
      input_guess = @request.params['guess']
      if input_guess.size == 4
        res = @game.make_guess(input_guess.to_s)
        if res == :lose || res == '++++'
          save_result(get_name, res, secret_code)
          res = 'You lose'
          res = 'You win' if res == '++++'
          response.set_cookie('result', res)
          response.redirect('/result')
          next
        else
          @request.session['last_guesses'] << "#{res}   (#{input_guess})" if res.size
        end
      end

      response.set_cookie('result', result)
      response.redirect('/game')
    end
  end

  def get_hint
    Rack::Response.new do |response|
      response.redirect('/') and next unless @playing
      hint = @game.get_hint
      response.set_cookie('hint', hint)
      response.redirect('/game')
    end
  end

  def show_result
    if secret_code.nil?
      Rack::Response.new do |response|
        response.redirect('/')
      end
    else
      Rack::Response.new(render('result.html.erb'))
    end
  end

  def get_name
    @player_name
  end

  def not_found
    Rack::Response.new('Not Found', 404)
  end

  def set_name(name)
    player_name = name
    player_name = 'stranger' if player_name == ''
    @request.session['player_name'] = player_name
  end

  def clear_cookies(response)
    response.set_cookie('result', 'none')
    response.set_cookie('hint', 'none')
  end

  def attempts
    @request.session['game_obj']&.attempts
  end

  def hint
    @request.cookies['hint'] || 'none'
  end

  def result
    @request.cookies['result'] || 'Nothing'
  end

  def secret_code
     @request.session['game_obj']&.get_secret_code
  end

  def last_guesses
    content = ""
    @last_guesses.each_with_index { |item, i| content << "#{i+1}. #{item} <br>"} if @last_guesses.size
    content
  end

  def save_result(name, res, code)
    res = "attempts: #{res}" if res != :lose
    data = [ { "name" => name, 'result' => res, "code" => code } ]
    File.open("./results.yml", "a") {|f| f.write(data.to_yaml) }
  end

  def load_results
    begin
      parsed = YAML.load(File.open("./results.yml"))
    rescue Exception => e
      puts "Not found"
    end
  end

  def render(template)
    path = File.expand_path("../views/#{template}", __FILE__)
    ERB.new(File.read(path)).result(binding)
  end
end
