#include "platform/web_server.h"
#include <iostream>
#include <fstream>
#include <sstream>

WebServer::WebServer(int port) : port_(port)
{
    setupCORS();
}

void WebServer::setDatabase(std::shared_ptr<Database> db)
{
    db_ = db;
}

void WebServer::setupCORS()
{
    server_.set_pre_routing_handler([](const httplib::Request &req, httplib::Response &res)
                                    {
        res.set_header("Access-Control-Allow-Origin", "*");
        res.set_header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
        res.set_header("Access-Control-Allow-Headers", "Content-Type, Authorization");
        
        if (req.method == "OPTIONS") {
            res.status = 200;
            return httplib::Server::HandlerResponse::Handled;
        }
        return httplib::Server::HandlerResponse::Unhandled; });
}

void WebServer::setupRoutes()
{
    // Serve static files
    server_.set_mount_point("/", "./web");

    // API Routes
    server_.Get("/api/students", [this](const auto &req, auto &res) { handleGetStudents(req, res); });
    server_.Post("/api/students", [this](const auto &req, auto &res) { handleAddStudent(req, res); });
    server_.Get("/api/companies", [this](const auto &req, auto &res) { handleGetCompanies(req, res); });
    server_.Post("/api/companies", [this](const auto &req, auto &res) { handleAddCompany(req, res); });
    server_.Get("/api", [this](const httplib::Request &req, httplib::Response &res) { handleGetRoot(req, res); });
    server_.Post("/api/schedule/generate", [this](const httplib::Request &req, httplib::Response &res) { handleGenerateSchedule(req, res); });
    server_.Get("/api/schedule", [this](const httplib::Request &req, httplib::Response &res) { handleGetSchedule(req, res); });
    server_.Get("/api/statistics", [this](const httplib::Request &req, httplib::Response &res) { handleGetStatistics(req, res); });
}

void WebServer::handleGetRoot(const httplib::Request &req, httplib::Response &res)
{
    json response = {
        {"message", "CRISP Platform API"},
        {"version", "1.0.0"},
        {"status", "running"},
        {"endpoints", {"/api/schedule/generate - POST", "/api/schedule - GET", "/api/students - GET/POST", "/api/companies - GET/POST", "/api/statistics - GET"}}
    };
    sendJsonResponse(res, response);
}

void WebServer::handleGenerateSchedule(const httplib::Request &req, httplib::Response &res)
{
    try
    {
        std::cout << "Received schedule generation request\n";
        std::cout << "Request body: " << req.body << std::endl;

        json requestData = json::parse(req.body);

        // Initialize scheduler
        InterviewScheduler scheduler;

        // Default time slot: 9 AM to 5 PM
        int startTime = 9 * 60; // 9 AM
        int endTime = 17 * 60;  // 5 PM

        if (requestData.contains("timeSlot"))
        {
            startTime = requestData["timeSlot"].value("startTime", startTime);
            endTime = requestData["timeSlot"].value("endTime", endTime);
        }

        scheduler.initialize(TimeSlot(startTime, endTime));

        // Add companies from request
        if (requestData.contains("companies"))
        {
            for (const auto &company : requestData["companies"])
            {
                scheduler.addCompany(company["name"], company["durationPerRound"], company["numRounds"], company["numPanels"]);
                std::cout << "Added company: " << company["name"] << std::endl;
            }
        }

        // Add students from request
        if (requestData.contains("students"))
        {
            for (const auto &studentJson : requestData["students"])
            {
                std::string id = studentJson["id"];
                std::string name = studentJson.value("name", "");
                std::vector<std::string> shortlisted = studentJson["shortlistedCompanies"];
                scheduler.addStudent(id, name, shortlisted);
            }
        }

        // Generate schedule
        auto conflicts = scheduler.generateSchedule();
        auto schedule = scheduler.getSchedule();

        // Prepare response
        json response;
        response["success"] = true;
        response["conflicts"] = conflicts;
        response["schedule"] = json::array();
        response["statistics"] = {
            {"totalInterviews", schedule.size()},
            {"totalConflicts", conflicts.size()},
            {"successRate", conflicts.empty() ? 100.0 : 0.0}
        };

        for (const auto &interview : schedule)
        {
            response["schedule"].push_back(interviewToJson(interview));
        }

        std::cout << "Generated " << schedule.size() << " interviews with " << conflicts.size() << " conflicts\n";

        sendJsonResponse(res, response);
    }
    catch (const json::parse_error &e)
    {
        std::cerr << "JSON parse error: " << e.what() << std::endl;
        sendErrorResponse(res, "Invalid JSON format: " + std::string(e.what()), 400);
    }
    catch (const std::exception &e)
    {
        std::cerr << "Error generating schedule: " << e.what() << std::endl;
        sendErrorResponse(res, "Error generating schedule: " + std::string(e.what()), 500);
    }
}
void WebServer::handleGetStatistics(const httplib::Request &req, httplib::Response &res) {
    json response = {
        {"totalStudents", 0},
        {"totalCompanies", 0},
        {"totalInterviews", 0},
        {"successRate", 0.0}
    };
    sendJsonResponse(res, response);
}

void WebServer::handleGetSchedule(const httplib::Request &req, httplib::Response &res)
{
    json response = {
        {"message", "Schedule endpoint - use POST /api/schedule/generate to create schedules"}
    };
    sendJsonResponse(res, response);
}

void WebServer::handleGetStudents(const httplib::Request &req, httplib::Response &res)
{
    auto students = db_->getAllStudents();
    json response = json::array();
    for (const auto &student : students)
    {
        response.push_back(studentToJson(student));
    }
    sendJsonResponse(res, response);
}

void WebServer::handleAddStudent(const httplib::Request &req, httplib::Response &res)
{
    auto body = json::parse(req.body);
    Student student;
    student.rollNumber = body["rollNumber"];
    student.name = body["name"];
    student.shortlistedCompanies = body["shortlistedCompanies"].get<std::vector<std::string>>();
    if (db_->addStudent(student))
    {
        sendJsonResponse(res, {{"success", true}});
    }
    else
    {
        sendErrorResponse(res, "Failed to add student", 500);
    }
}

void WebServer::handleGetCompanies(const httplib::Request &req, httplib::Response &res)
{
    auto companies = db_->getAllCompanies();
    json response = json::array();
    for (const auto &company : companies)
    {
        response.push_back(companyToJson(company));
    }
    sendJsonResponse(res, response);
}

void WebServer::handleAddCompany(const httplib::Request &req, httplib::Response &res)
{
    auto body = json::parse(req.body);
    Company company;
    company.name = body["name"];
    company.durationPerRound = body["durationPerRound"];
    company.numRounds = body["numRounds"];
    company.numPanels = body["numPanels"];
    if (db_->addCompany(company))
    {
        sendJsonResponse(res, {{"success", true}});
    }
    else
    {
        sendErrorResponse(res, "Failed to add company", 500);
    }
}

json WebServer::interviewToJson(const Interview &interview)
{
    return {
        {"studentId", interview.studentId},
        {"companyName", interview.companyName},
        {"round", interview.round},
        {"startTime", interview.timeSlot.startTime},
        {"endTime", interview.timeSlot.endTime},
        {"panelId", interview.panelId}
    };
}

json WebServer::companyToJson(const Company &company)
{
    return {
        {"name", company.name},
        {"durationPerRound", company.durationPerRound},
        {"numRounds", company.numRounds},
        {"numPanels", company.numPanels}
    };
}

json WebServer::studentToJson(const Student &student)
{
    return {
        {"rollNumber", student.rollNumber},
        {"name", student.name},
        {"shortlistedCompanies", student.shortlistedCompanies}
    };
}

void WebServer::sendJsonResponse(httplib::Response &res, const json &data, int status)
{
    res.status = status;
    res.set_content(data.dump(2), "application/json");
}

void WebServer::sendErrorResponse(httplib::Response &res, const std::string &error, int status)
{
    json errorResponse = {
        {"success", false},
        {"error", error}
    };
    sendJsonResponse(res, errorResponse, status);
}

void WebServer::start()
{
    std::cout << "Starting CRISP Platform Web Server on port " << port_ << std::endl;
    std::cout << "Access the platform at: http://localhost:" << port_ << std::endl;
    server_.listen("0.0.0.0", port_);
}

void WebServer::stop()
{
    server_.stop();
}
