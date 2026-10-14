// CRISP Platform JavaScript Application

class CRISPApp {
    constructor() {
        this.currentTab = 'schedule';
        this.currentResultTab = 'schedule';
        this.lastResults = null;
        this.init();
    }

    init() {
        this.setupEventListeners();
        console.log('CRISP Platform initialized');
    }

    setupEventListeners() {
        // Tab switching
        document.querySelectorAll('.tab-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.switchTab(e.target.dataset.tab);
            });
        });

        // Result tabs
        document.querySelectorAll('.result-tab-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.switchResultTab(e.target.dataset.resultTab);
            });
        });

        // Form validation
        document.getElementById('companies').addEventListener('input', this.validateJSON);
        document.getElementById('students').addEventListener('input', this.validateJSON);
    }

    switchTab(tabName) {
        // Update button states
        document.querySelectorAll('.tab-btn').forEach(btn => {
            btn.classList.remove('active');
        });
        document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');

        // Update content visibility
        document.querySelectorAll('.tab-content').forEach(content => {
            content.classList.remove('active');
        });
        document.getElementById(tabName).classList.add('active');

        this.currentTab = tabName;
    }

    switchResultTab(tabName) {
        document.querySelectorAll('.result-tab-btn').forEach(btn => {
            btn.classList.remove('active');
        });
        document.querySelector(`[data-result-tab="${tabName}"]`).classList.add('active');

        document.querySelectorAll('.result-tab-content').forEach(content => {
            content.classList.remove('active');
        });
        document.getElementById(`${tabName}-results`).classList.add('active');

        this.currentResultTab = tabName;
    }

    validateJSON(event) {
        const textarea = event.target;
        try {
            JSON.parse(textarea.value);
            textarea.style.borderColor = '#059669';
        } catch (e) {
            textarea.style.borderColor = '#dc2626';
        }
    }

    timeToMinutes(timeString) {
        const [hours, minutes] = timeString.split(':').map(Number);
        return hours * 60 + minutes;
    }

    minutesToTime(minutes) {
        const hours = Math.floor(minutes / 60);
        const mins = minutes % 60;
        const period = hours < 12 ? 'AM' : 'PM';
        const displayHours = hours === 0 ? 12 : hours > 12 ? hours - 12 : hours;
        return `${displayHours}:${mins.toString().padStart(2, '0')} ${period}`;
    }

    async generateSchedule() {
        try {
            this.showLoading();

            // Get form data
            const startTime = this.timeToMinutes(document.getElementById('startTime').value);
            const endTime = this.timeToMinutes(document.getElementById('endTime').value);
            const companies = JSON.parse(document.getElementById('companies').value);
            const students = JSON.parse(document.getElementById('students').value);

            // Validate time range
            if (startTime >= endTime) {
                throw new Error('End time must be after start time');
            }

            const requestData = {
                timeSlot: { startTime, endTime },
                companies,
                students
            };

            console.log('Sending request:', requestData);

            const response = await fetch('/api/schedule/generate', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(requestData)
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const result = await response.json();
            console.log('Received result:', result);

            this.lastResults = result;
            this.displayResults(result);
            this.switchTab('results');

        } catch (error) {
            console.error('Error generating schedule:', error);
            alert(`Error: ${error.message}`);
        } finally {
            this.hideLoading();
        }
    }

    displayResults(result) {
        // Show summary
        document.getElementById('resultsSummary').style.display = 'block';
        document.getElementById('totalInterviews').textContent = result.statistics?.totalInterviews || 0;
        document.getElementById('totalConflicts').textContent = result.statistics?.totalConflicts || 0;
        document.getElementById('successRate').textContent = `${result.statistics?.successRate || 0}%`;

        // Display schedule
        this.displaySchedule(result.schedule || []);

        // Display conflicts
        this.displayConflicts(result.conflicts || []);

        // Display raw data
        document.getElementById('raw-output').textContent = JSON.stringify(result, null, 2);
    }

    displaySchedule(schedule) {
        const scheduleDisplay = document.getElementById('schedule-display');
        
        if (schedule.length === 0) {
            scheduleDisplay.innerHTML = '<p>No interviews scheduled.</p>';
            return;
        }

        // Group by student
        const studentSchedules = {};
        schedule.forEach(interview => {
            if (!studentSchedules[interview.studentId]) {
                studentSchedules[interview.studentId] = [];
            }
            studentSchedules[interview.studentId].push(interview);
        });

        let html = '';
        for (const [studentId, interviews] of Object.entries(studentSchedules)) {
            // Sort interviews by start time
            interviews.sort((a, b) => a.startTime - b.startTime);
            
            html += `
                <div class="student-schedule">
                    <h4>${studentId} Schedule</h4>
                    <table class="schedule-table">
                        <thead>
                            <tr>
                                <th>Company</th>
                                <th>Round</th>
                                <th>Start Time</th>
                                <th>End Time</th>
                                <th>Panel</th>
                            </tr>
                        </thead>
                        <tbody>
            `;

            interviews.forEach(interview => {
                html += `
                    <tr>
                        <td>${interview.companyName}</td>
                        <td>${interview.round}</td>
                        <td>${this.minutesToTime(interview.startTime)}</td>
                        <td>${this.minutesToTime(interview.endTime)}</td>
                        <td>${interview.panelId + 1}</td>
                    </tr>
                `;
            });

            html += '</tbody></table></div>';
        }

        scheduleDisplay.innerHTML = html;
    }

    displayConflicts(conflicts) {
        const conflictsDisplay = document.getElementById('conflicts-display');
        
        if (conflicts.length === 0) {
            conflictsDisplay.innerHTML = '<p style="color: #059669; font-weight: 500;">✅ No conflicts detected! All interviews scheduled successfully.</p>';
            return;
        }

        let html = '<h4>Scheduling Conflicts:</h4>';
        conflicts.forEach(conflict => {
            html += `<div class="conflict-item">⚠️ ${conflict}</div>`;
        });

        conflictsDisplay.innerHTML = html;
    }

    clearForm() {
        document.getElementById('companies').value = '';
        document.getElementById('students').value = '';
        document.getElementById('startTime').value = '09:00';
        document.getElementById('endTime').value = '17:00';
    }

    showLoading() {
        document.getElementById('loadingModal').style.display = 'block';
    }

    hideLoading() {
        document.getElementById('loadingModal').style.display = 'none';
    }
}

// Global functions for HTML onclick handlers
function generateSchedule() {
    app.generateSchedule();
}

function clearForm() {
    app.clearForm();
}

// Initialize app when page loads
let app;
document.addEventListener('DOMContentLoaded', () => {
    app = new CRISPApp();
});
