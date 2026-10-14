#pragma once

#include <sqlite3.h>
#include <string>
#include <vector>
#include <memory>
#include <optional>

#include "core/InterviewScheduler.h"  // For Student and Company structs

class Database {
private:
    sqlite3* db_;
    std::string dbPath_;

public:
    Database(const std::string& dbPath);
    ~Database();

    bool initialize();
    bool executeSQL(const std::string& sql);

    // Database operations for students and companies
    bool addStudent(const Student& student);
    bool addCompany(const Company& company);
    std::vector<Student> getAllStudents();
    std::vector<Company> getAllCompanies();

private:
    void createTables();
};
