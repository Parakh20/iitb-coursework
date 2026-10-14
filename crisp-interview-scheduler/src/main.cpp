#include <iostream>
#include <memory>
#include <signal.h>
#include "platform/web_server.h"
#include "platform/database.h"
#include "core/InterviewScheduler.h"

// Global server pointer for signal handling
std::unique_ptr<WebServer> globalServer;

void signalHandler(int signal)
{
    std::cout << "\nReceived signal " << signal << ". Shutting down gracefully..." << std::endl;
    if (globalServer)
    {
        globalServer->stop();
    }
    exit(0);
}

int main(int argc, char *argv[])
{
    std::cout << "========================================" << std::endl;
    std::cout << "  CRISP Platform v1.0.0" << std::endl;
    std::cout << "  Campus Recruitment Interview" << std::endl;
    std::cout << "  Scheduling Platform" << std::endl;
    std::cout << "========================================" << std::endl;

    // Default configuration
    int port = 8080;
    std::string dbPath = "/home/parakh/crisp-platform/data/crisp_platform.db";

    // Parse command line arguments for port and db path
    for (int i = 1; i < argc; i++)
    {
        std::string arg = argv[i];
        if (arg == "--port" && i + 1 < argc)
        {
            port = std::stoi(argv[++i]);
        }
        else if (arg == "--db" && i + 1 < argc)
        {
            dbPath = argv[++i];
        }
        else if (arg == "--help" || arg == "-h")
        {
            std::cout << "\nUsage: " << argv[0] << " [options]" << std::endl;
            std::cout << "Options:" << std::endl;
            std::cout << "  --port <port>    Server port (default: 8080)" << std::endl;
            std::cout << "  --db <path>      Database path (default: data/crisp_platform.db)" << std::endl;
            std::cout << "  --help, -h       Show this help message" << std::endl;
            return 0;
        }
    }

    try
    {
        // Initialize database connection
        auto database = std::make_shared<Database>(dbPath);
        if (!database->initialize())
        {
            std::cerr << "Failed to initialize database!" << std::endl;
            return 1;
        }
        std::cout << "Database initialized: " << dbPath << std::endl;

        // Create and setup web server
        globalServer = std::make_unique<WebServer>(port);
        globalServer->setDatabase(database);
        globalServer->setupRoutes();

        // Setup signal handlers for graceful shutdown
        signal(SIGINT, signalHandler);
        signal(SIGTERM, signalHandler);

        // Test the core scheduling algorithm - simple test case
        std::cout << "\nTesting core scheduling algorithm..." << std::endl;
        InterviewScheduler testScheduler;
        testScheduler.initialize(TimeSlot(9 * 60, 17 * 60)); // 9 AM to 5 PM
        testScheduler.addCompany("Test Company", 30, 2, 2);
        testScheduler.addStudent("TEST001", "Test Student", {"Test Company"});

        auto conflicts = testScheduler.generateSchedule();
        std::cout << "Core algorithm test: " << (conflicts.empty() ? "PASSED" : "FAILED") << std::endl;

        // Start the web server (blocking call)
        std::cout << "\n🚀 Starting web server..." << std::endl;
        std::cout << "🌐 Access the platform at: http://localhost:" << port << std::endl;
        std::cout << "📊 API available at: http://localhost:" << port << "/api" << std::endl;
        std::cout << "⚡ Press Ctrl+C to stop the server" << std::endl;

        globalServer->start();
    }
    catch (const std::exception &e)
    {
        std::cerr << "Fatal error: " << e.what() << std::endl;
        return 1;
    }

    return 0;
}
