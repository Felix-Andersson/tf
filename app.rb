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

#Vad är regular expressions i Validerings pp:n ?? Fråga Emil

#Lägg till .to_s på alla params

before('/protected/*') do
    if (session[:id] == nil)
        #Användare har inte loggat in och försöker nå en sida förutom '/' och '/showregister'
        redirect('/')
    end
end

get('/') do
    slim(:login)
end

post('/login') do       #ENDA SOM ÄR KVAR ÄR ATT FIXA MED TID MELLAN LOGIN (FINNS HÖGST UPP)
    username = params[:username]
    password = params[:password]
    db = connect_database()
    result = db.execute("SELECT * FROM user WHERE username = ?", username).first
    password_digest = result["password"]
    id = result["id"]
    role = result["role"]

    if BCrypt::Password.new(password_digest) == password
        session[:id] = id
        session[:role] = role
        redirect('/protected/home') #Här redirectar vi 
    else
        flash[:notice] = "Wrong details entered!"
        redirect('/')
    end
end

get('/showregister') do
    slim(:register)
end

post('/register') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    role = params[:role]


    if register_validation(username,password,password_confirm)
        #Användaren klarade inte valideringen
        redirect('/showregister')
    else
        #lägg till användare
        password_digest = BCrypt::Password.create(password)
        db = SQLite3::Database.new("db/database.db")
        #Sätt rollen till false eftersom det är vanlig användare och inte admin
        db.execute("INSERT INTO user (username, password, role) VALUES (?,?,?)", username, password_digest, role)
        redirect('/')
    end
end

def register_validation(username, password, password_confirm)
    #Kolla så att fälten ej är tomma
    if username.empty? or password.empty? or password_confirm.empty?
        flash[:notice] = "Fields can not be left empty!"
        return true
    end

    #Kolla så att användarnamn inte redan finns i databasen
    db = connect_database()
    result = db.execute("SELECT * FROM user WHERE username = ?", username)
    if not result.empty?
        flash[:notice] = "Username already exists in database!"
        return true
    end

    #Kolla längden på användarnamn samt lösenord
    if username.length < 3 or username.length > 12       #Användarnamn
        flash[:notice] = "Username needs to be withing the range!"
        return true
    elsif password.length < 3 or password.length > 12    #Lösenord
        flash[:notice] = "Passwords needs to be withing the range!"
        return true
    end
    
    #Kolla så att löseorden stämmer överens
    if password != password_confirm
        flash[:notice] = "Passwords are not matching!"
        return true
    else
        return false
    end
end

get('/logout') do
    flash[:notice] = "You have been logged out!"
    session.clear
    redirect('/')
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

post('/protected/gods/:id/update') do
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
    @comment_result = db.execute("SELECT * FROM comment WHERE god_id = ?", god_id)
    @comment_result2 = db.execute("SELECT user.username FROM comment INNER JOIN user ON comment.user_id = user.id WHERE comment.god_id = ?", god_id)
    slim(:'gods/show')
end

get('/protected/profile/edit') do
    user_id = session[:id]
    db = connect_database()
    @result = db.execute("SELECT * FROM user WHERE id = ?", user_id).first
    slim(:profile)
end

post('/protected/profile/update') do
    username = params[:username]
    bio = params[:bio]
    
    db = SQLite3::Database.new("db/database.db")
    db.execute("UPDATE user SET username = ?,bio = ?",username,bio)
    redirect('/protected/profile/edit')
end

post('/protected/comment/new') do
    content = params[:content].to_s
    god_id = params[:god_id].to_i
    user_id = session[:id]
    time = Time.new
    date = "#{time.year}-#{time.month}-#{time.day}"

    db = SQLite3::Database.new("db/database.db")
    db.execute("INSERT INTO comment (user_id, god_id, date, content) VALUES (?,?,?,?)", user_id, god_id, date, content)
    redirect("/protected/gods/#{god_id}")
end