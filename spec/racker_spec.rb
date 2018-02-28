require 'rack/test'
require 'rspec'
require 'codebreaker'

describe 'Racker' do
  include Rack::Test::Methods

  def app
    Rack::Builder.parse_file('config.ru').first
  end

  context "with not started game" do
    it "index have status 200" do
      get "/"
      expect(last_response.status).to eq(200)
    end

    it "get /play have status 200" do
      get "/play"
      expect(last_response.status).to eq(200)
    end

    it "get /play shows index page" do
      get "/play"
      expect(last_response.body).to include "Enter your name:"
    end

    it "get /result should redirect to index" do
      get "/result"
      follow_redirect!
      expect(last_request.path).to eq "/"
    end

    it "get /make_guess should redirect to index" do
      get "/make_guess"
      follow_redirect!
      expect(last_request.path).to eq "/"
    end

    it "get /hint should redirect to index" do
      get "/hint"
      follow_redirect!
      expect(last_request.path).to eq "/"
    end

    it "get /start_game starts game with name stranger" do
      get "/start_game"
      follow_redirect!
      expect(last_response.body).to include "Player: stranger"
    end
  end

  it "starts game with name Tester" do
    post "/start_game", { player_name: "Tester" }
    follow_redirect!
    expect(last_response.body).to include "Player: Tester"
  end

  context "with started game" do
    let!(:game) { get "/start_game"; follow_redirect! }

    it "does not have hint" do
      expect(last_response.body).not_to include "HINT:"
    end

    it "shows hint" do
      get "/hint"
      follow_redirect!
      expect(last_response.body).to include "HINT:"
    end

    it "get /result should redirect to index" do
      get "/result"
      follow_redirect!
      expect(last_request.path).to eq "/"
    end

    it "make incorrect guess" do
      post "/make_guess", { guess: "" }
      follow_redirect!
      expect(last_request.path).to eq "/play"
      expect(last_response.body).not_to include "Last guesses:"
    end

    it "make correct guess" do
      post "/make_guess", { guess: "4444" }
      follow_redirect!
      expect(last_response.body).to include "Last guesses:"
      expect(last_response.body).to include "4444"
    end
  end

  describe "request to 404" do
    let(:path) { '/some_404path' }
    before { get path }

    it "respond Not found" do
      expect(last_response.body).to include "Not Found"
    end

    it "respond have 404 status" do
      expect(last_response.status).to eq(404)
    end
  end
end
