require 'slim'
require 'sinatra'
require 'bcrypt'
require 'sinatra/reloader'
require 'sqlite3'

get('/') do
    slim(:login)
end