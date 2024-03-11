def connect_database()
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    return db
end

#def insert_god_into_database()
#    db = SQLite3::Database.new("db/database.db")
#    db.execute("INSERT INTO god (name, mythology_id, content) VALUES (?,?,?)", array_with_values[], )