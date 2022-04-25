
package main

import (
    _ "github.com/go-sql-driver/mysql"
    "context"
    "database/sql"
    "fmt"
    "log"
    "net/http"
    "os"
    "time"
)

func handler(w http.ResponseWriter, r *http.Request) {
    db := getConnection(true)
    // Insert data into the database
    insForm, err := db.Prepare("INSERT INTO ping.history(message) VALUES (?)")
    if err != nil {
        panic(err.Error())
    }
    insForm.Exec(r.URL.Path[1:])
    defer db.Close()
    // Return the inserted value
    fmt.Fprintf(w, "Value inserted: %s\n", r.URL.Path[1:])
}

// Main entry point
func main() {
    dbInit()
    http.HandleFunc("/", handler)
    log.Fatal(http.ListenAndServe(":8080", nil))
}

// Initialize a database `ping` with a table `history`
func dbInit() {
    ctx, cancelfunc := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancelfunc()
    db := getConnection(false)
    _, err := db.ExecContext(ctx, "CREATE DATABASE IF NOT EXISTS ping;")
    if err != nil {
        panic(err.Error())
    }
    _, err = db.ExecContext(ctx, "CREATE TABLE IF NOT EXISTS ping.history (message CHAR(255));")
    if err != nil {
        panic(err.Error())
    }
    defer db.Close()
}

// Open a new connection
func getConnection(useDB bool) (*sql.DB) {
    // Get connection properties
    dbDriver := getEnv("MYSQL_DRIVER", "mysql")
    dbUser := getEnv("MYSQL_USER", "root")
    dbPass := getEnv("MYSQL_PASSWORD", "")
    dbName := getEnv("MYSQL_DATABASE", "ping")
    if(!useDB){
        dbName = ""
    }
    dbHost := getEnv("MYSQL_HOST", "127.0.0.1")
    dbPort := getEnv("MYSQL_PORT", "3306")
    // Build the connection
    db, err := sql.Open(dbDriver, dbUser+":"+dbPass+"@tcp("+dbHost+":"+dbPort+")/"+dbName)
    if err != nil {
        panic(err.Error())
    }
    return db
}

// Get an environment variable or a default value
func getEnv(key, defaultValue string) string {
    value := os.Getenv(key)
    if len(value) == 0 {
        return defaultValue
    }
    return value
}
