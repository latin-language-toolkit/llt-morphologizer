require 'sinatra/base'
require 'sinatra/respond_with'
require 'llt/morphologizer'

class Api < Sinatra::Base
  register Sinatra::RespondWith

  get '/morphologize' do
    # TODO

    respond_to do |f|
      f.xml {}
    end
  end
end
