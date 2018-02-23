require 'yaml'
require 'yaml/store'

class FileService
  def initialize(request)
    @request = request
    @session = @request.session
    @game = @session['game_obj']
  end

  DEFAULT_FILENAME = 'results.yml'.freeze

  def save_result(res)
    return if res == :lose
    data = { name: @session['player_name'], code: @game.get_secret_code }
    store = YAML::Store.new DEFAULT_FILENAME
    store.transaction do
      store['results'] = store['results'].to_a.unshift(data)
    end
  end

  def load_results
    parsed = YAML.load_file(DEFAULT_FILENAME)
    parsed['results']
  rescue Exception => e
  end
end
