def connect_database()
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    return db
end

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

#def insert_god_into_database()
#    db = SQLite3::Database.new("db/database.db")
#    db.execute("INSERT INTO god (name, mythology_id, content) VALUES (?,?,?)", array_with_values[], )