require 'slim'
require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'bcrypt'
require 'sqlite3'
require_relative './model.rb'

enable :sessions

include Model

#Vad är regular expressions i Validerings pp:n ?? Fråga Emil

#Lägg till .to_s på alla params


#Betyg i nuläget: C+. 
#[fixat] Förslag till komplettering (B): Finslipa REST-namngivning.
#
#Säkra även upp känsliga routes, tex delete och update (kolla det är samma person som är inloggad som även äger resursen som ska tas bort/uppdateras). ->
# -> kolla säkringen i app.rb istället för visuellt i slim filerna
#I nuläget kollas endast om man är inloggad eller ej.
#
#(A): Yarddoc. Färdigställ planerad elements-sida.
#
#MVC fullt ut. -> vart ligger kod?
#
#[fixat] On Delete Cascade-liknande funktionalitet (ta bort relaterade resurser i andra tabeller on en resurs försvinnerm tex en gud).


# Ensures authorization before accessing the route for creating a new god
#
# @see authorization_check
before('/protected/gods/new') do
    authorization_check()
end

# Ensures authorization before accessing the route for editing a god
#
# @see authorization_check
before(%r{/protected/gods/[^/]+/edit}) do
    authorization_check()
end

# Ensures authorization before accessing the route for deleting a god
#
# @see authorization_check
before(%r{/protected/gods/[^/]+/delete}) do
    authorization_check()
end

# Checks authorization before editing a comment
#
# @param [Integer] comment_id, The ID of the comment to be edited
# @see comment_check
before(%r{/protected/comments/([^/]+)/edit}) do
    |comment_id|
    comment_check(comment_id.to_i)
end

# Checks authorization before deleting a comment
#
# @param [Integer] comment_id, The ID of the comment to be deleted
# @see comment_check
before(%r{/protected/comments/([^/]+)/delete}) do
    |comment_id|
    comment_check(comment_id.to_i)
end

# Checks if the user is logged in before accessing protected routes
#
# @see Model#register_user
before('/protected/*') do
    if (session[:id] == nil)
        #Användare har inte loggat in och försöker nå en sida förutom '/' och '/showregister'
        redirect('/')
    end
end

# Displays the login page
get('/') do
    slim(:login)
end

# Logs in the user
#
# @param [String] username, The username
# @param [String] password, The password
# @see login_timer
# @see login_decrypt
post('/login') do
    username = params[:username]
    password = params[:password]
    result = select_db("user", "username", username)
    password_digest = result["password"]
    id = result["id"]
    role = result["role"]

    login_timer()
    login_decrypt(password_digest, password, id, role)
end

# Displays the registration page
get('/showregister') do
    slim(:register)
end

# Registers a new user
#
# @param [String] username, The username
# @param [String] password, The password
# @param [String] password_confirm, The repeated password
# @param [String] role, The role of the user
# @see register_validation
# @see register_user_db
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

# Logs out the user
get('/logout') do
    flash[:notice] = "You have been logged out!"
    session.clear
    redirect('/')
end

# Displays the home page for authenticated users
get('/protected/home') do
    @result = select_all_db("god")
    slim(:home)
end

# Displays all elements
get('/protected/elements') do
    @result = select_all_db("element")
    slim(:'elements/index')
end

# Displays a specific element
get('/protected/elements/:id') do
    element_id = params[:id]
    @result = select_god_element_db(element_id)
    slim(:'elements/show')
end

# Displays all gods
get('/protected/gods') do
    @result = select_all_db("god")
    slim(:'gods/index')
end

# Displays the form for creating a new god
get('/protected/gods/new') do
    @result = select_all_db("element")
    slim(:'gods/new')
end

# Creates a new god
#
# @param [String] name, The name of the god
# @param [String] mythology, The mythology of the god
# @param [String] content, The content related to the god
# @see create_god_db
post('/protected/gods') do
    name = params[:name].to_s
    mythology = params[:mythology]
    content = params[:content].to_s

    create_god_db(name, mythology, content)
    #Find god_id
    result = select_db("god", "name", name)

    elements = params.select { |key, _| key.start_with?('element_') }
    elements_values = elements.values

    elements_values.each do |element|
        create_god_element_relation(result, element)
    end
    redirect('/protected/gods')
end

# Displays the form for editing a god
get('/protected/gods/:id/edit') do
    god_id = params[:id].to_i
    db = connect_database()
    @result = select_db("god", "id", god_id)
    @result2 = select_god_myth_db(god_id)
    slim(:'gods/edit')
end

# Updates information of an existing god
#
# @param [Integer] id, The ID of the god to be updated
# @param [String] name, The updated name of the god
# @param [String] mythology, The updated mythology of the god
# @param [String] content, The updated content related to the god
# @see god_update_db
post('/protected/gods/:id/update') do
    god_id = params[:id].to_i
    name = params[:name].to_s
    mythology = params[:mythology]
    content = params[:content]

    god_update_db(name, mythology, content, god_id)
    redirect('/protected/gods')
end

# Deletes a god and its related data
#
# @param [Integer] id, The ID of the god to be deleted
# @see delete_db
# @see delete_god_element_rel_db
post('/protected/gods/:id/delete') do
    god_id = params[:id].to_i
    delete_db("god", "id", god_id)
    delete_db("comment", "god_id", god_id)  #Tar bort alla kommentarer från just den gud-sidan i databasen
    delete_god_element_rel_db(god_id)   #Tar bort alla gud element relationer
    redirect('/protected/gods')
end

# Displays details of a specific god
get('/protected/gods/:id') do
    god_id = params[:id]
    @result = select_db("god", "id", god_id)
    @result2 = select_god_myth_db(god_id)
    @comment_result = select_db("comment", "god_id", god_id, false)
    @comment_result2 = select_user_comment_db(god_id)
    slim(:'gods/show')
end

# Displays the form for editing user profiles
get('/protected/profiles/edit') do
    user_id = session[:id]
    @result = select_db("user", "id", user_id)
    slim(:'profiles/edit')
end

# Updates user profile information
#
# @param [String] username, The updated username
# @param [String] bio, The updated biography
# @see profile_update_db
post('/protected/profiles/update') do
    username = params[:username].to_s
    bio = params[:bio].to_s
    user_id = session[:id].to_i
    
    profile_update_db(username, bio, user_id)
    redirect('/protected/profile/edit')
end

# Creates a new comment
#
# @param [String] content, The content of the comment
# @param [Integer] god_id, The ID of the god the comment is related to
# @see create_comment_db
post('/protected/comments') do
    content = params[:content].to_s
    god_id = params[:god_id].to_i
    user_id = session[:id].to_i
    time = Time.new
    date = "#{time.year}-#{time.month}-#{time.day}"

    create_comment_db(user_id, god_id, date, content)
    redirect("/protected/gods/#{god_id}")
end

# Displays the form for editing a comment
get('/protected/comments/:id/edit') do
    comment_id = params[:id].to_i
    @result = select_db("comment", "id", comment_id)
    slim(:'comments/edit')
end

# Updates an existing comment
#
# @param [Integer] id, The ID of the comment to be updated
# @param [String] content, The updated content of the comment
# @see comment_update_db
post('/protected/comments/:id/update') do
    comment_id = params[:id].to_i
    content = params[:content]

    comment_update_db(content, comment_id)
    redirect('/protected/gods')
end

# Deletes a comment
#
# @param [Integer] id, The ID of the comment to be deleted
# @param [Integer] god_id, The ID of the god the comment is related to
# @see delete_db
post('/protected/comments/:id/delete') do
    comment_id = params[:id].to_i
    god_id = params[:god_id].to_i
    delete_db("comment", "id", comment_id)
    redirect("/protected/gods/#{god_id}")
end