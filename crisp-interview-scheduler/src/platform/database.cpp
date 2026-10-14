#include "platform/database.h"
#include <iostream>

Database::Database(const std::string& dbPath) : db_(nullptr), dbPath_(dbPath) {}

Database::~Database() {
    if (db_) {
        sqlite3_close(db_);
    }
}

bool Database::initialize() {
    int result = sqlite3_open(dbPath_.c_str(), &db_);
    if (result != SQLITE_OK) {
        std::cerr << "Cannot open database: " << sqlite3_errmsg(db_) << std::endl;
        return false;
    }
    
    createTables();
    return true;
}

bool Database::executeSQL(const std::string& sql) {
    char* errMsg = nullptr;
    int result = sqlite3_exec(db_, sql.c_str(), nullptr, nullptr, &errMsg);
    
    if (result != SQLITE_OK) {
        std::cerr << "SQL error: " << errMsg << std::endl;
        sqlite3_free(errMsg);
        return false;
    }
    
    return true;
}

void Database::createTables() {
    std::string createStudentsTable = R"(
        CREATE TABLE IF NOT EXISTS students (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            roll_number TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            branch TEXT,
            cgpa REAL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
    )";
    
    std::string createCompaniesTable = R"(
        CREATE TABLE IF NOT EXISTS companies (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            duration_per_round INTEGER NOT NULL,
            num_rounds INTEGER NOT NULL,
            num_panels INTEGER NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
    )";
    
    std::string createInterviewsTable = R"(
        CREATE TABLE IF NOT EXISTS interviews (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id TEXT NOT NULL,
            company_name TEXT NOT NULL,
            round INTEGER NOT NULL,
            start_time INTEGER NOT NULL,
            end_time INTEGER NOT NULL,
            panel_id INTEGER NOT NULL,
            status TEXT DEFAULT 'scheduled',
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
    )";
    
    executeSQL(createStudentsTable);
    executeSQL(createCompaniesTable);
    executeSQL(createInterviewsTable);
}

bool Database::addStudent(const Student& student) {
    std::string sql = "INSERT INTO students (roll_number, name) VALUES (?, ?);";
    sqlite3_stmt* stmt;
    if (sqlite3_prepare_v2(db_, sql.c_str(), -1, &stmt, nullptr) != SQLITE_OK) {
        std::cerr << "Failed to prepare statement for addStudent\n";
        return false;
    }
    sqlite3_bind_text(stmt, 1, student.rollNumber.c_str(), -1, SQLITE_STATIC);
    sqlite3_bind_text(stmt, 2, student.name.c_str(), -1, SQLITE_STATIC);

    int rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    if (rc != SQLITE_DONE) {
        std::cerr << "Failed to execute addStudent statement\n";
        return false;
    }
    return true;
}

std::vector<Student> Database::getAllStudents() {
    std::vector<Student> students;
    std::string sql = "SELECT roll_number, name FROM students;";
    sqlite3_stmt* stmt;
    if (sqlite3_prepare_v2(db_, sql.c_str(), -1, &stmt, nullptr) != SQLITE_OK) {
        std::cerr << "Failed to prepare statement for getAllStudents\n";
        return students;
    }
    
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        std::string roll = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 0));
        std::string name = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 1));
        students.push_back(Student(roll, name));
    }
    
    sqlite3_finalize(stmt);
    return students;
}

bool Database::addCompany(const Company& company) {
    std::string sql = "INSERT INTO companies (name, duration_per_round, num_rounds, num_panels) VALUES (?, ?, ?, ?);";
    sqlite3_stmt* stmt;
    if (sqlite3_prepare_v2(db_, sql.c_str(), -1, &stmt, nullptr) != SQLITE_OK) {
        std::cerr << "Failed to prepare statement for addCompany\n";
        return false;
    }
    
    sqlite3_bind_text(stmt, 1, company.name.c_str(), -1, SQLITE_STATIC);
    sqlite3_bind_int(stmt, 2, company.durationPerRound);
    sqlite3_bind_int(stmt, 3, company.numRounds);
    sqlite3_bind_int(stmt, 4, company.numPanels);

    int rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    if (rc != SQLITE_DONE) {
        std::cerr << "Failed to execute addCompany statement\n";
        return false;
    }
    return true;
}

std::vector<Company> Database::getAllCompanies() {
    std::vector<Company> companies;
    std::string sql = "SELECT name, duration_per_round, num_rounds, num_panels FROM companies;";
    sqlite3_stmt* stmt;
    if (sqlite3_prepare_v2(db_, sql.c_str(), -1, &stmt, nullptr) != SQLITE_OK) {
        std::cerr << "Failed to prepare statement for getAllCompanies\n";
        return companies;
    }
    
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        std::string name = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 0));
        int duration = sqlite3_column_int(stmt, 1);
        int rounds = sqlite3_column_int(stmt, 2);
        int panels = sqlite3_column_int(stmt, 3);
        companies.push_back(Company(name, duration, rounds, panels));
    }
    
    sqlite3_finalize(stmt);
    return companies;
}
