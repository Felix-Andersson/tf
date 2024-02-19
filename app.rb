require 'slim'
require 'sinatra'
require 'bcrypt'
require 'sinatra/reloader'
require 'sqlite3'
require_relative './model.rb'

enable :sessions

#db = connect_database()
#@result = db.execute("SELECT * FROM element")

before() do
    if (session[:id] == nil) && (request.path_info == '/protected/*')
        #Användare har inte loggat in och försöker nå en sida förutom '/' och '/showregister'
        print("REDIRECTED TO LOGIN BECAUSE IT IS PROTECTED!! Here is path: #{request.path_info} : end of path")
        redirect('/')
    end
end

get('/') do
    slim(:login)
end

post('/login') do
    username = params[:username]
    password = params[:password]
    db = connect_database()
    result = db.execute("SELECT * FROM user WHERE username = ?", username).first
    password_digest = result["password"]
    id = result["id"]

    if BCrypt::Password.new(pwdigest) == password
        session[:id] = id
        session[:username] = username
        redirect('/showregister') #Här redirectar vi 
    else
        "Wrong details entered."
    end
end


get('/showregister') do
    slim(:register)
end

post('/register') do
    username = params[:username]
    password = params[:password]

    #lägg till användare
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new("db/database.db")
    #Sätt rollen till false eftersom det är vanlig användare och inte admin
    db.execute("INSERT INTO user (username, password, role) VALUES (?,?,false)", username, password_digest)
    redirect('/')
end

