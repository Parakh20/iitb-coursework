#pragma once

#include <iostream>
#include <vector>
#include <string>
#include <map>
#include <algorithm>
#include <iomanip>

struct TimeSlot {
    int startTime; // minutes from start of day
    int endTime;
    
    TimeSlot(int start = 0, int end = 0) : startTime(start), endTime(end) {}
    
    bool overlaps(const TimeSlot& other) const {
        return !(endTime <= other.startTime || startTime >= other.endTime);
    }
};

struct Company {
    std::string name;
    int durationPerRound;
    int numRounds;
    int numPanels;
    
    Company(std::string n = "", int dur = 0, int rounds = 0, int panels = 0)
        : name(n), durationPerRound(dur), numRounds(rounds), numPanels(panels) {}
};

struct Interview {
    std::string studentId;
    std::string companyName;
    int round;
    TimeSlot timeSlot;
    int panelId;
    
    Interview() : round(0), panelId(0) {}
    Interview(std::string sid, std::string comp, int r, TimeSlot ts, int pid)
        : studentId(sid), companyName(comp), round(r), timeSlot(ts), panelId(pid) {}
};

struct Student {
    std::string rollNumber;
    std::string name;
    std::vector<std::string> shortlistedCompanies;

    Student(std::string roll = "", std::string nm = "")  // <--- add name here
        : rollNumber(roll), name(nm) {}
};


class InterviewScheduler {
private:
    std::map<std::string, Company> companies;
    std::map<std::string, Student> students;
    std::vector<Interview> schedule;
    TimeSlot availableSlot;
    std::map<std::string, std::vector<std::vector<bool>>> panelAvailability;
    std::map<std::string, std::vector<TimeSlot>> studentSchedule;
    int timeSlotDuration = 15; // 15-minute granularity

    // Helper methods
    int timeToSlot(int minutes);
    int slotToTime(int slotIndex);
    int getTotalSlots();
    bool isStudentAvailable(const std::string& studentId, const TimeSlot& slot);
    bool isPanelAvailable(const std::string& companyName, int panelId, const TimeSlot& slot);
    void reservePanel(const std::string& companyName, int panelId, const TimeSlot& slot);
    void releasePanel(const std::string& companyName, int panelId, const TimeSlot& slot);
    int findAvailablePanel(const std::string& companyName, const TimeSlot& slot);
    bool scheduleStudentInterviews(const std::string& studentId, int companyIndex, std::vector<Interview>& currentSchedule);

public:
    void initialize(const TimeSlot& slot);
    void addCompany(const std::string& name, int duration, int rounds, int panels);
    void addStudent(const std::string& rollNumber, const std::string& name, const std::vector<std::string>& shortlistedCompanies);

    std::vector<std::string> generateSchedule();
    std::vector<Interview> getSchedule() const;
    std::string timeToString(int minutes);
    void printStudentSchedule(const std::string& studentId);
    void printCompleteSchedule();
};
