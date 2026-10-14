#include "core/InterviewScheduler.h"

using namespace std;

int InterviewScheduler::timeToSlot(int minutes) {
    return (minutes - availableSlot.startTime) / timeSlotDuration;
}

int InterviewScheduler::slotToTime(int slotIndex) {
    return availableSlot.startTime + (slotIndex * timeSlotDuration);
}

int InterviewScheduler::getTotalSlots() {
    return (availableSlot.endTime - availableSlot.startTime) / timeSlotDuration;
}

bool InterviewScheduler::isStudentAvailable(const string& studentId, const TimeSlot& slot) {
    for (const auto& existingSlot : studentSchedule[studentId]) {
        if (slot.overlaps(existingSlot)) {
            return false;
        }
    }
    return true;
}

bool InterviewScheduler::isPanelAvailable(const string& companyName, int panelId, const TimeSlot& slot) {
    int startSlot = timeToSlot(slot.startTime);
    int endSlot = timeToSlot(slot.endTime);
    
    for (int i = startSlot; i < endSlot; i++) {
        if (i >= (int)panelAvailability[companyName][panelId].size() || 
            panelAvailability[companyName][panelId][i]) {
            return false;
        }
    }
    return true;
}

void InterviewScheduler::reservePanel(const string& companyName, int panelId, const TimeSlot& slot) {
    int startSlot = timeToSlot(slot.startTime);
    int endSlot = timeToSlot(slot.endTime);
    
    for (int i = startSlot; i < endSlot; i++) {
        panelAvailability[companyName][panelId][i] = true;
    }
}

void InterviewScheduler::releasePanel(const string& companyName, int panelId, const TimeSlot& slot) {
    int startSlot = timeToSlot(slot.startTime);
    int endSlot = timeToSlot(slot.endTime);
    
    for (int i = startSlot; i < endSlot; i++) {
        panelAvailability[companyName][panelId][i] = false;
    }
}

int InterviewScheduler::findAvailablePanel(const string& companyName, const TimeSlot& slot) {
    for (int panelId = 0; panelId < companies[companyName].numPanels; panelId++) {
        if (isPanelAvailable(companyName, panelId, slot)) {
            return panelId;
        }
    }
    return -1; // No available panel
}

bool InterviewScheduler::scheduleStudentInterviews(const string& studentId, int companyIndex, vector<Interview>& currentSchedule) {
    if (companyIndex >= (int)students[studentId].shortlistedCompanies.size()) {
        return true;
    }

    string companyName = students[studentId].shortlistedCompanies[companyIndex];
    Company& company = companies[companyName];
    vector<Interview> companyInterviews;
    int currentTime = availableSlot.startTime;

    // Try scheduling rounds sequentially
    for (int round = 1; round <= company.numRounds; round++) {
        bool roundScheduled = false;
        
        for (int startTime = currentTime; 
             startTime + company.durationPerRound <= availableSlot.endTime; 
             startTime += timeSlotDuration) {
            
            TimeSlot proposedSlot(startTime, startTime + company.durationPerRound);
            
            if (!isStudentAvailable(studentId, proposedSlot)) continue;
            
            int panelId = findAvailablePanel(companyName, proposedSlot);
            if (panelId == -1) continue;

            Interview interview(studentId, companyName, round, proposedSlot, panelId);
            companyInterviews.push_back(interview);
            reservePanel(companyName, panelId, proposedSlot);
            studentSchedule[studentId].push_back(proposedSlot);
            currentTime = proposedSlot.endTime;
            roundScheduled = true;
            break;
        }

        if (!roundScheduled) {
            // Backtrack - release resources for this company
            for (auto& i : companyInterviews) {
                releasePanel(i.companyName, i.panelId, i.timeSlot);
            }
            studentSchedule[studentId].erase(
                studentSchedule[studentId].end() - (int)companyInterviews.size(),
                studentSchedule[studentId].end()
            );
            return false;
        }
    }

    // Add current company's interviews to schedule
    for (const auto& i : companyInterviews) {
        currentSchedule.push_back(i);
    }

    // Try next company
    if (scheduleStudentInterviews(studentId, companyIndex + 1, currentSchedule)) {
        return true;
    }

    // Backtrack - remove this company's interviews
    for (auto& i : companyInterviews) {
        releasePanel(i.companyName, i.panelId, i.timeSlot);
    }
    studentSchedule[studentId].erase(
        studentSchedule[studentId].end() - (int)companyInterviews.size(),
        studentSchedule[studentId].end()
    );
    currentSchedule.erase(
        currentSchedule.end() - (int)companyInterviews.size(),
        currentSchedule.end()
    );
    return false;
}

void InterviewScheduler::initialize(const TimeSlot& slot) {
    availableSlot = slot;
    schedule.clear();
    panelAvailability.clear();
    studentSchedule.clear();
}

void InterviewScheduler::addCompany(const string& name, int duration, int rounds, int panels) {
    companies[name] = Company(name, duration, rounds, panels);
    int totalSlots = getTotalSlots();
    panelAvailability[name] = vector<vector<bool>>(panels, vector<bool>(totalSlots, false));
}

void InterviewScheduler::addStudent(const std::string& rollNumber, const std::string& name, const std::vector<std::string>& shortlistedCompanies) {
    students[rollNumber] = Student(rollNumber, name);
    students[rollNumber].shortlistedCompanies = shortlistedCompanies;
}


vector<string> InterviewScheduler::generateSchedule() {
    vector<string> conflicts;

    // Sort students by fewest shortlisted companies first (greedy)
    vector<pair<int, string>> studentOrder;
    for (const auto& student : students) {
        studentOrder.push_back({(int)student.second.shortlistedCompanies.size(), student.first});
    }
    sort(studentOrder.begin(), studentOrder.end());

    for (const auto& studentPair : studentOrder) {
        string studentId = studentPair.second;
        vector<Interview> studentInterviews;
        
        if (!scheduleStudentInterviews(studentId, 0, studentInterviews)) {
            conflicts.push_back("Cannot schedule all interviews for student " + studentId);
            continue;
        }

        for (const auto& i : studentInterviews) {
            schedule.push_back(i);
        }
    }

    return conflicts;
}

vector<Interview> InterviewScheduler::getSchedule() const {
    return schedule;
}

string InterviewScheduler::timeToString(int minutes) {
    int hours = minutes / 60;
    int mins = minutes % 60;
    string period = (hours < 12) ? "AM" : "PM";
    
    if (hours == 0) hours = 12;
    else if (hours > 12) hours -= 12;
    
    char buffer[10];
    snprintf(buffer, sizeof(buffer), "%d:%02d %s", hours, mins, period.c_str());
    return std::string(buffer);
}

void InterviewScheduler::printStudentSchedule(const string& studentId) {
    cout << "\n" << studentId << " Schedule:\n";
    cout << string(50, '=') << "\n";
    cout << setw(12) << "Company" << setw(8) << "Round"
         << setw(12) << "Start" << setw(12) << "End" << setw(8) << "Panel\n";
    cout << string(50, '-') << "\n";

    vector<Interview> studentInterviews;
    for (const auto& i : schedule) {
        if (i.studentId == studentId) {
            studentInterviews.push_back(i);
        }
    }

    sort(studentInterviews.begin(), studentInterviews.end(),
         [](const Interview& a, const Interview& b) { 
             return a.timeSlot.startTime < b.timeSlot.startTime; 
         });

    for (const auto& i : studentInterviews) {
        cout << setw(12) << i.companyName
             << setw(8) << i.round
             << setw(12) << timeToString(i.timeSlot.startTime)
             << setw(12) << timeToString(i.timeSlot.endTime)
             << setw(8) << i.panelId + 1 << "\n";
    }
}

void InterviewScheduler::printCompleteSchedule() {
    map<string, vector<Interview>> studentGroups;
    for (const auto& i : schedule) {
        studentGroups[i.studentId].push_back(i);
    }

    for (auto& p : studentGroups) {
        sort(p.second.begin(), p.second.end(),
             [](const Interview& a, const Interview& b) { 
                 return a.timeSlot.startTime < b.timeSlot.startTime; 
             });
        printStudentSchedule(p.first);
    }
}
