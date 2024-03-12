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

get('/protected/gods/:id/edit') do
    god_id = params[:id].to_i
    db = connect_database()
    @result = db.execute("SELECT * FROM god WHERE id = ?",god_id).first
    @result2 = db.execute("SELECT mythology.name FROM god INNER JOIN mythology ON god.mythology_id = mythology.id WHERE god.id = ?",god_id).first
    slim(:'gods/edit')
end

post('/protected/gods/:id/update') do #HAr inte fixat
    god_id = params[:id].to_i
    name = params[:name].to_s
    mythology = params[:mythology]
    content = params[:content]

    db = SQLite3::Database.new("db/database.db")
    db.execute("UPDATE god SET name = ?,mythology_id = ?,content = ? WHERE id = ?",name,mythology,content,god_id)
    redirect('/protected/gods')
  end

post('/protected/gods/:id/delete') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/database.db")
    db.execute("DELETE FROM god WHERE id = ?",id)
    redirect('/protected/gods')
end

get('/protected/gods/:id') do
    god_id = params[:id].to_i
    db = connect_database()
    @result = db.execute("SELECT * FROM god WHERE id = ?",god_id).first
    @result2 = db.execute("SELECT mythology.name FROM god INNER JOIN mythology ON god.mythology_id = mythology.id WHERE god.id = ?",god_id).first
    slim(:'gods/show')
end

