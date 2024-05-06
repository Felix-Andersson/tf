module Model

    # Connects to the SQLite3 database
    #
    # @return [SQLite3::Database] The connected database object
    def connect_database()
        db = SQLite3::Database.new("db/database.db")
        db.results_as_hash = true
        return db
    end

    #VALIDERINGS FUNKTIONER
    #Login Variabel
    $time_login = 0
    $login_array = [] # [ [ip,tid] [ip,tid] ]

    # Checks if login attempts are within a specified time interval
    # and limits login frequency
    #
    # @see login_decrypt
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

    # Decrypts the password and logs in the user if credentials match
    #
    # @param [String] password_digest The hashed password stored in the database
    # @param [String] password The password entered by the user
    # @param [Integer] id The ID of the user
    # @param [String] role The role of the user
    # @see login_timer
    def login_decrypt(password_digest, password, id, role)
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

    # Validates user registration input
    #
    # @param [String] username The username entered by the user
    # @param [String] password The password entered by the user
    # @param [String] password_confirm The repeated password entered by the user
    # @return [Boolean] True if validation fails, False otherwise
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

    # Checks authorization before accessing protected routes
    def authorization_check()
        if session[:role] != "true"
            #Användare har inte admin
            redirect('/')
        end
    end

    # Checks authorization before editing a comment
    #
    # @param [Integer] comment_id The ID of the comment to be edited
    def comment_check(comment_id)
        db = connect_database()
        result = select_db("comment", "id", comment_id)
        if session[:role] != "true" and session[:id] != result["user_id"]
            #Användare har inte admin eller äger inte kommentaren
            redirect('/')
        end
    end

    #GENERELLA FUNKTIONER SOM TAR IN ARGUMENT

    # Selects data from the database based on provided criteria
    #
    # @param [String] table The table name
    # @param [String] column The column name to match against
    # @param [String] row The value to match in the specified column
    # @param [Boolean] first If true, returns only the first matching row, otherwise returns all matches
    # @return [Array] The matching row(s) from the database
    def select_db(table, column, row, first=true)
        db = connect_database()
        if first
            return db.execute("SELECT * FROM #{table} WHERE #{column} = ?", row).first
        else
            return db.execute("SELECT * FROM #{table} WHERE #{column} = ?", row)
        end
    end

    # Selects all data from a specified table in the database
    #
    # @param [String] table The table name
    # @return [Array] All rows from the specified table
    def select_all_db(table)
        db = connect_database()
        return db.execute("SELECT * FROM #{table}")
    end

    # Deletes data from the database based on provided criteria
    #
    # @param [String] table The table name
    # @param [String] column The column name to match against
    # @param [String] row The value to match in the specified column
    def delete_db(table, column, row)
        db = SQLite3::Database.new("db/database.db")
        db.execute("DELETE FROM #{table} WHERE #{column} = ?", row)
    end


    #SPECIFIKA FUNKTIONER FÖR EN HÄNDELSE #
    #Insert Into

    # Inserts a new user into the database
    #
    # @param [String] username The username of the new user
    # @param [String] password_digest The hashed password of the new user
    # @param [String] role The role of the new user
    def register_user_db(username, password_digest, role)
        db = SQLite3::Database.new("db/database.db")
        db.execute("INSERT INTO user (username, password, role) VALUES (?,?,?)", username, password_digest, role)
    end

    # Inserts a new god into the database
    #
    # @param [String] name The name of the god
    # @param [Integer] mythology The ID of the mythology associated with the god
    # @param [String] content The content related to the god
    def create_god_db(name, mythology, content)
        #Insert god
        db = SQLite3::Database.new("db/database.db")
        db.execute("INSERT INTO god (name, mythology_id, content) VALUES (?,?,?)", name, mythology, content)
    end

    # Creates a relation between a god and an element in the database
    #
    # @param [Hash] result The result of the query for the god
    # @param [Integer] element_id The ID of the element to relate to the god
    def create_god_element_relation(result, element_id)
        db = connect_database()
        #Insert into god_element_rel table
        db.execute("INSERT INTO god_element_relation (god_id, element_id) VALUES (?,?)", result['id'], element_id)
    end

    # Inserts a new comment into the database
    #
    # @param [Integer] user_id The ID of the user who posted the comment
    # @param [Integer] god_id The ID of the god the comment is related to
    # @param [String] date The date the comment was posted
    # @param [String] content The content of the comment
    def create_comment_db(user_id, god_id, date, content)
        db = SQLite3::Database.new("db/database.db")
        db.execute("INSERT INTO comment (user_id, god_id, date, content) VALUES (?,?,?,?)", user_id, god_id, date, content)
    end

    #Update

    # Updates an existing god in the database
    #
    # @param [String] name The updated name of the god
    # @param [Integer] mythology The updated mythology associated with the god
    # @param [String] content The updated content related to the god
    # @param [Integer] god_id The ID of the god to be updated
    def god_update_db(name, mythology, content, god_id)
        db = SQLite3::Database.new("db/database.db")
        db.execute("UPDATE god SET name = ?,mythology_id = ?,content = ? WHERE id = ?", name, mythology, content, god_id)
    end

    # Updates user profile information in the database
    #
    # @param [String] username The updated username
    # @param [String] bio The updated biography
    # @param [Integer] user_id The ID of the user to be updated
    def profile_update_db(username, bio, user_id)
        db = SQLite3::Database.new("db/database.db")
        db.execute("UPDATE user SET username = ?,bio = ? WHERE id = ?", username, bio, user_id)
    end

    # Updates an existing comment in the database
    #
    # @param [String] content The updated content of the comment
    # @param [Integer] comment_id The ID of the comment to be updated
    def comment_update_db(content, comment_id)
        db = SQLite3::Database.new("db/database.db")
        db.execute("UPDATE comment SET content = ? WHERE id = ?",content,comment_id)
    end

    #Inner join

    # Selects the mythology associated with a specific god from the database
    #
    # @param [Integer] god_id The ID of the god
    # @return [Array] The mythology associated with the specified god
    def select_god_myth_db(god_id)
        db = connect_database()
        return db.execute("SELECT mythology.name FROM god INNER JOIN mythology ON god.mythology_id = mythology.id WHERE god.id = ?",god_id).first
    end

    # Selects user comments related to a specific god from the database
    #
    # @param [Integer] god_id The ID of the god
    # @return [Array] User comments related to the specified god
    def select_user_comment_db(god_id)
        db = connect_database()
        return db.execute("SELECT user.username, user.id FROM comment INNER JOIN user ON comment.user_id = user.id WHERE comment.god_id = ?", god_id)
    end

    # Selects gods associated with a specific element from the database
    #
    # @param [Integer] element_id The ID of the element
    # @return [Array] Gods associated with the specified element
    def select_god_element_db(element_id)
        db = connect_database()
        return db.execute("SELECT god.name, god.id FROM god_element_relation INNER JOIN god ON god_element_relation.god_id = god.id WHERE god_element_relation.element_id = ?", element_id)
    end

    # Deletes god-element relations from the database
    #
    # @param [Integer] god_id The ID of the god whose relations are to be deleted
    def delete_god_element_rel_db(god_id)
        db = connect_database()
        db.execute("DELETE FROM god_element_relation WHERE god_id = ?", god_id)
    end
end