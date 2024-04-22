require 'slim'
require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'bcrypt'
require 'sqlite3'
require_relative './model.rb'

enable :sessions

#Vad är regular expressions i Validerings pp:n ?? Fråga Emil

#Lägg till .to_s på alla params


#Betyg i nuläget: C+. 
# [fixat] Förslag till komplettering (B): Finslipa REST-namngivning.
#
#Säkra även upp känsliga routes, tex delete och update (kolla det är samma person som är inloggad som även äger resursen som ska tas bort/uppdateras). ->
# -> kolla säkringen i app.rb istället för visuellt i slim filerna
#I nuläget kollas endast om man är inloggad eller ej.
#
#(A): Yarddoc. Färdigställ planerad elements-sida.
#
# MVC fullt ut. -> vart ligger kod?
#
# [fixat, (inte för element sida)] On Delete Cascade-liknande funktionalitet (ta bort relaterade resurser i andra tabeller on en resurs försvinnerm tex en gud).

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
    result = select_db("user", "username", username)
    password_digest = result["password"]
    id = result["id"]
    role = result["role"]

    login_timer()
    login_decrypt()
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
        register_user_db(username, password_digest, role)
        redirect('/')
    end
end

get('/logout') do
    flash[:notice] = "You have been logged out!"
    session.clear
    redirect('/')
end

get('/protected/home') do
    @result = select_all_db("god")
    slim(:home)
end

get('/protected/elements') do
    @result = select_all_db("element")
    slim(:elements)
end

get('/protected/gods') do
    @result = select_all_db("god")
    slim(:'gods/index')
end

get('/protected/gods/new') do
    slim(:'gods/new')
end

post('/protected/gods') do
    name = params[:name].to_s
    mythology = params[:mythology]
    content = params[:content]

    create_god_db(name, mythology, content)
    redirect('/protected/gods')
end

get('/protected/gods/:id/edit') do
    god_id = params[:id].to_i
    db = connect_database()
    @result = select_db("god", "id", god_id)
    @result2 = select_god_myth_db(god_id)
    slim(:'gods/edit')
end

post('/protected/gods/:id/update') do
    god_id = params[:id].to_i
    name = params[:name].to_s
    mythology = params[:mythology]
    content = params[:content]

    god_update_db(name, mythology, content, god_id)
    redirect('/protected/gods')
end

post('/protected/gods/:id/delete') do
    god_id = params[:id].to_i
    delete_db("god", "id", god_id)
    delete_db("comment", "god_id", god_id)  #Tar bort alla kommentarer från just den gud-sidan i databasen
    #Ta bort från gud, element rel tabellen här också
    redirect('/protected/gods')
end

get('/protected/gods/:id') do
    god_id = params[:id].to_i
    @result = select_db("god", "id", god_id)
    @result2 = select_god_myth_db(god_id)
    @comment_result = select_db("comment", "god_id", god_id, false)
    @comment_result2 = select_user_comment_db(god_id)
    slim(:'gods/show')
end

get('/protected/profiles/edit') do
    user_id = session[:id]
    @result = select_db("user", "id", user_id)
    slim(:'profiles/edit')
end

post('/protected/profiles/update') do
    username = params[:username].to_s
    bio = params[:bio].to_s
    user_id = session[:id].to_i
    
    profile_update_db(username, bio, user_id)
    redirect('/protected/profile/edit')
end

post('/protected/comments') do
    content = params[:content].to_s
    god_id = params[:god_id].to_i
    user_id = session[:id].to_i
    time = Time.new
    date = "#{time.year}-#{time.month}-#{time.day}"

    create_comment_db(user_id, god_id, date, content)
    redirect("/protected/gods/#{god_id}")
end

get('/protected/comments/:id/edit') do
    comment_id = params[:id].to_i
    @result = select_db("comment", "id", comment_id)
    slim(:'comments/edit')
end

post('/protected/comments/:id/update') do
    comment_id = params[:id].to_i
    content = params[:content]

    comment_update_db(content, comment_id)
    redirect('/protected/gods')
end

post('/protected/comments/:id/delete') do
    comment_id = params[:id].to_i
    god_id = params[:god_id].to_i
    delete_db("comment", "id", comment_id)
    redirect("/protected/gods/#{god_id}")
end