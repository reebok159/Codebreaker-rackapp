require './lib/racker'

use Rack::Session::Pool
use Rack::Static, urls: ['/stylesheets'], root: 'public'

run Racker
