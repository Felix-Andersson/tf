def connect_database()
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    return db
end