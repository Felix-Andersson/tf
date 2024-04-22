require 'sinatra/flash'

def connect_database()
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    return db
end

# VALIDERINGS FUNKTIONER
#Login Variabel
$time_login = 0
$login_array = [] # [ [ip,tid] [ip,tid] ]

def login_timer()
    if (not $login_array.empty?) #Om arrayen inte är tom
        i=0
        already_exists = false
        while i<$login_array.length #Loopa igenom alla element i arrayen
            if $login_array[i][0] = request.ip #Om ip:n finns
                already_exists = true
                if $login_array[i][1]+10 > Time.now.to_i    #Om inlogget är inom 10 sekunder av det senaste inlogget
                    flash[:notice] = "You can't login this often!"
                    redirect('/')   #Ladda om sidan och gör ingenting
                end
                break
            end
            i+=1

        end
        if already_exists   #Om ip:n redan finns i login_array
            $login_array[i][1] = Time.now.to_i #Lägg in tiden för ip addressen
        else
            $login_array << [request.ip, Time.now.to_i] #Lägg in ett nytt element med ip:n
        end
    else #Om login_array är tom, lägg in ett nytt element med ip:n
        $login_array << [request.ip, Time.now.to_i]
    end
end

def login_decrypt()
    if BCrypt::Password.new(password_digest) == password
        session[:id] = id
        session[:role] = role
        $time_login = Time.now.to_i
        redirect('/protected/home') #Här redirectar vi 
    else
        flash[:notice] = "Wrong details entered!"
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
    result = select_db("user", "username", username, false)
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

# GENERELLA FUNKTIONER SOM TAR IN ARGUMENT
def select_db(table, column, row, first=true)
    db = connect_database()
    if first
        return db.execute("SELECT * FROM #{table} WHERE #{column} = ?", row).first
    else
        return db.execute("SELECT * FROM #{table} WHERE #{column} = ?", row)
    end
end

def select_all_db(table)
    db = connect_database()
    return db.execute("SELECT * FROM #{table}")
end

def delete_db(table, column, row)
    db = SQLite3::Database.new("db/database.db")
    db.execute("DELETE FROM #{table} WHERE #{column} = ?", row)
end


# SPECIFIKA FUNKTIONER FÖR EN HÄNDELSE #
#Insert Into
def register_user_db(username, password_digest, role)
    db = SQLite3::Database.new("db/database.db")
    db.execute("INSERT INTO user (username, password, role) VALUES (?,?,?)", username, password_digest, role)
end

def create_god_db(name, mythology, content)
    db = SQLite3::Database.new("db/database.db")
    db.execute("INSERT INTO god (name, mythology_id, content) VALUES (?,?,?)", name, mythology, content)
end

def create_comment_db(user_id, god_id, date, content)
    db = SQLite3::Database.new("db/database.db")
    db.execute("INSERT INTO comment (user_id, god_id, date, content) VALUES (?,?,?,?)", user_id, god_id, date, content)
end

#Update
def god_update_db(name, mythology, content, god_id)
    db = SQLite3::Database.new("db/database.db")
    db.execute("UPDATE god SET name = ?,mythology_id = ?,content = ? WHERE id = ?", name, mythology, content, god_id)
end

def profile_update_db(username, bio, user_id)
    db = SQLite3::Database.new("db/database.db")
    db.execute("UPDATE user SET username = ?,bio = ? WHERE id = ?", username, bio, user_id)
end

def comment_update_db(content, comment_id)
    db = SQLite3::Database.new("db/database.db")
    db.execute("UPDATE comment SET content = ? WHERE id = ?",content,comment_id)
end

#Inner join
def select_god_myth_db(god_id)
    return db.execute("SELECT mythology.name FROM god INNER JOIN mythology ON god.mythology_id = mythology.id WHERE god.id = ?",god_id).first
end

def select_user_comment_db(god_id)
    return db.execute("SELECT user.username, user.id FROM comment INNER JOIN user ON comment.user_id = user.id WHERE comment.god_id = ?", god_id)
end