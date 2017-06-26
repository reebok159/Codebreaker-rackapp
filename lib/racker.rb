require 'erb'
require 'codebreaker'

class Racker
  def self.call(env)
    new(env).response.finish
  end

  def initialize(env)
    @request = Rack::Request.new(env)

  end

  def response
    case @request.path
    when '/' then Rack::Response.new(render('index.html.erb'))
    when '/start_game'
      Rack::Response.new do |response|
        game = Codebreaker::Game.new
        game.start
        @request.env['rack.session']['game_obj'] = game
        @request.env['rack.session']['last_guesses'] = []
        @request.env['rack.session']['playing'] = true
        player_name = @request.params['player_name']
        player_name = "stranger" if player_name == ''
        @request.env['rack.session']['player_name'] = player_name
        response.set_cookie('result', 'none')
        response.set_cookie('hint', 'none')
        response.redirect('/game')
    end
    when '/make_guess'
      Rack::Response.new do |response|
        get_session_variables
        unless @playing
          response.redirect('/')
          next
        end
        response.set_cookie('hint', 'none')

        input_guess = @request.params['guess']
        if input_guess.size == 4
          result = @game.make_guess("#{input_guess}")

          if(result == :lose || result == "++++")
            if result == "++++"
              result = 'You win'
            else
             result = 'You lose'
            end
            response.set_cookie('result', result)
            response.redirect('/result')
            next
          else
            @request.env['rack.session']['last_guesses'] << "#{result}   (#{input_guess})" if result.size
          end
        end

        response.set_cookie('result', result)
        response.redirect('/game')
    end

    when '/game'
      get_session_variables
      if !@playing
        Rack::Response.new(render('index.html.erb'))
      else
        Rack::Response.new(render('game.html.erb'))
      end
    when '/hint'
      Rack::Response.new do |response|
        get_session_variables
        hint = @game.get_hint
        response.set_cookie('hint', hint)
        response.redirect('/game')
      end
    when '/result' then Rack::Response.new(render('result.html.erb'))
    else Rack::Response.new('Not Found', 404)
    end
  end


  def get_session_variables
    @game = @request.env['rack.session']['game_obj']
    @last_guesses = @request.env['rack.session']['last_guesses']
    @playing = @request.env['rack.session']['playing']
    @player_name = @request.env['rack.session']['player_name']
  end

  def get_name
    @player_name
  end

  def attempts
    @request.env['rack.session']['game_obj'].attempts
  end

  def render(template)
    path = File.expand_path("../views/#{template}", __FILE__)
    ERB.new(File.read(path)).result(binding)
  end


  def hint
    @request.cookies['hint'] || 'none'
  end

  def result
    @request.cookies['result'] || 'Nothing'
  end

  def secret_code
     @request.env['rack.session']['game_obj'].get_secret_code
  end

  def last_guesses
    content = ""
    @last_guesses.each_with_index { |item, i| content << "#{i+1}. #{item} <br>"} if @last_guesses.size
    content
  end

end
