require 'slim'
require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'bcrypt'
require 'sqlite3'
require_relative './model.rb'

enable :sessions

#Skriv ut datum genom att:
#time = Time.new
#puts "#{time.year}-#{time.month}-#{time.day}"
#och sätt sedan in det i date i databasen på comment

#db = connect_database()
#@result = db.execute("SELECT * FROM element")

before('/protected/*') do
    if (session[:id] == nil)
        #Användare har inte loggat in och försöker nå en sida förutom '/' och '/showregister'
        print("REDIRECTED TO LOGIN BECAUSE IT IS PROTECTED!! Here is path: #{request.path_info} -------")
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

    if BCrypt::Password.new(password_digest) == password
        session[:id] = id
        session[:username] = username
        flash[:notice] = "You have succesfully logged in!"
        redirect('/protected/home') #Här redirectar vi 
    else
        "Wrong details entered." #skrivs ut på skärmen
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

get('/logout') do
    flash[:notice] = "You have been logged out!"
    session.clear
    redirect('/showregister')
end

get('/protected/home') do
    slim(:home)
end

get('/protected/elements') do
    db = connect_database()
    @result = db.execute("SELECT * FROM element")
    slim(:elements)
end

get('/protected/gods') do
    db = connect_database()
    @result = db.execute("SELECT * FROM god")
    slim(:'gods/index')
end

get('/protected/gods/new') do
    slim(:'gods/new')
end

post('/protected/gods/new') do
    name = params[:name].to_s
    mythology = params[:mythology]
    content = params[:content]

    db = SQLite3::Database.new("db/database.db")
    db.execute("INSERT INTO god (name, mythology_id, content) VALUES (?,?,?)", name, mythology, content)
    redirect('/protected/gods')
end

get('/protected/gods/:id') do #har inte gjort än
    god_id = params[:id].to_i
    db = connect_database()
    @result = db.execute("SELECT * FROM god WHERE id = ?",god_id).first
    @result2 = db.execute("SELECT * FROM god INNER JOIN mythology ON god.mythology_id = mythology.id WHERE id = ?",god_id).first
    #@artist_result = db.execute("SELECT Name FROM artists WHERE ArtistId IN (SELECT ArtistId FROM albums WHERE AlbumId = ?)",id).first
    slim(:'gods/show')
end