#pragma once

#include <httplib.h>
#include <nlohmann/json.hpp>
#include <memory>
#include <thread>
#include "core/InterviewScheduler.h"
#include "platform/database.h"

using json = nlohmann::json;

class WebServer
{
private:
    httplib::Server server_;
    int port_;
    std::shared_ptr<Database> db_;

public:
    WebServer(int port);
    void setDatabase(std::shared_ptr<Database> db);
    void setupRoutes();
    void start();
    void stop();

private:
    // CORS middleware
    void setupCORS();

    // API endpoints
    void handleGetRoot(const httplib::Request &req, httplib::Response &res);
    void handleGenerateSchedule(const httplib::Request &req, httplib::Response &res);
    void handleGetSchedule(const httplib::Request &req, httplib::Response &res);
    void handleGetStudents(const httplib::Request &req, httplib::Response &res);
    void handleAddStudent(const httplib::Request &req, httplib::Response &res);
    void handleGetCompanies(const httplib::Request &req, httplib::Response &res);
    void handleAddCompany(const httplib::Request &req, httplib::Response &res);
    void handleGetStatistics(const httplib::Request &req, httplib::Response &res);

    // Utility methods
    void sendJsonResponse(httplib::Response &res, const json &data, int status = 200);
    void sendErrorResponse(httplib::Response &res, const std::string &error, int status = 400);
    json interviewToJson(const Interview &interview);
    json companyToJson(const Company &company);
    json studentToJson(const Student &student);
};
