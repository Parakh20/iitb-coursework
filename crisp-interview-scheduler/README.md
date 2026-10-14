# CRISP Platform v1.0.0

Campus Recruitment Interview Scheduling Platform built in C++ with REST APIs and SQLite backend.

---

## Overview

CRISP automates and optimizes the scheduling of campus recruitment interviews by managing student and company data, generating conflict-free interview timetables, and exposing RESTful JSON APIs.

---

## Features

- Efficient scheduling using constraint satisfaction and greedy heuristics to avoid conflicts  
- SQLite persistent storage for students, companies, and interviews  
- C++ web server backend with JSON APIs  
- Graceful shutdown and configurable via command line  

---

## Technology Stack

- C++17, SQLite3  
- httplib (lightweight HTTP server)  
- nlohmann/json (JSON serialization)  
- CMake build system  

---

## Setup & Build

1. Clone the repository:

```bash
git clone https://github.com/Parakh20/CRISP
cd crisp-platform
```

2. Build the project:

```bash
./scripts/build.sh
```

3. Create the database folder (if not present):

```bash
mkdir -p data
```

---

## Running the Server

Run the server with default settings:

```bash
cd build
./crisp_platform
```

Or specify custom port and database path:

```bash
./crisp_platform --port 8080 --db /full/path/data/crisp_platform.db
```

Access the platform at:

```
http://localhost:8080
```

---

## API Endpoints

- `GET /api/students`  
- `POST /api/students`  
- `GET /api/companies`  
- `POST /api/companies`  
- `POST /api/schedule/generate`  
- `GET /api/statistics`  

---

## Scheduling Algorithm

Uses constraint satisfaction and greedy heuristics to assign interview panels and time slots without overlap.

---

## Signal Handling

Graceful shutdown on SIGINT/SIGTERM ensures no data loss.

---

## License

MIT License

---

## Contact
Parakh Sharma - sharmaparakh05@gmail.com
