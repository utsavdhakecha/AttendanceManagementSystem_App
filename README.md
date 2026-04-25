# 📋 CSE Department — Attendance Management System

A professional, hybrid-storage **Attendance Management System** built with **Flutter** for the Computer Science Engineering (CSE) Department. Features role-based access for Admin, HOD, Professors, and Students with real-time Firebase cloud sync and offline SQLite support.

---

## 📸 App Flow

```
Splash Screen → Role Selection → Login → Dashboard
```

**4 Roles:**
| Role | Purpose |
|------|---------|
| 🔴 **Admin** | Manage professors, subjects, HODs, divisions, students |
| 🔵 **Professor** | Mark attendance, manage timetable, view reports |
| 🟢 **HOD** | Department-wide attendance overview, approve leaves |
| 🟠 **Student** | View attendance, select electives, apply for leave |

---

## 🛠️ Technology Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter (Dart) |
| **Local Database** | SQLite (via `sqflite`) |
| **Cloud Database** | Firebase Firestore |
| **State Management** | Provider |
| **Charts** | fl_chart |
| **Reports** | CSV export & share |
| **Min SDK** | Dart SDK ^3.5.4 |

---

## 🚀 Setup & Installation

### Prerequisites

Make sure you have the following installed:
- **Flutter SDK** (3.x or later) — [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Android Studio** or **VS Code** with Flutter plugins
- **Android Emulator** or a physical Android device
- **Firebase account** — [Firebase Console](https://console.firebase.google.com/)

### Step 1: Clone / Extract the Project
```bash
### Option 1: Clone using Git
git clone https://github.com/your-username/AttendanceManagementSystem_App.git
cd AttendanceManagementSystem_App
```

### Option 2: Download ZIP
Download the ZIP file from GitHub, extract it, and open the extracted project folder (e.g., `AttendanceManagementSystem_App` or `AttendanceManagementSystem_App-main`) in your IDE.

### Step 2: Set Up Firebase (Required)

This app uses **Firebase Firestore** for cloud data. You need to create your own Firebase project:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Create a project"** → Name it anything (e.g., `attendance-system`)
3. Once created, click **"Add app"** → Select **Android**
4. Enter the package name: **`com.attendance.attendance_app`**
5. Click **Register App**
6. Download the `google-services.json` file
7. Place it in: `android/app/google-services.json`

> ⚠️ **The app will NOT build without this file.** If you already see a `google-services.json` in the project, you can use it directly for testing.

#### Firebase Console — Enable Firestore:
1. In your Firebase project, go to **Build → Firestore Database**
2. Click **Create Database**
3. Choose **Start in test mode** (for development)
4. Select a region and click **Enable**

### Step 3: Install Dependencies

```bash
flutter pub get
```

### Step 4: Run the App

```bash
flutter run
```

> On first launch, the app automatically seeds demo data (professors, students, subjects, attendance history) into your Firestore. This may take 30-60 seconds on the first run.

---

## 🔐 Demo Login Credentials

The app comes with pre-seeded demo data. Use these credentials to test:

### Admin
| Field | Value |
|-------|-------|
| Email | `admin@gmail.com` |
| Password | `admin123` |

### HOD
| Field | Value |
|-------|-------|
| Email | `hod@gmail.com` |
| Password | `hod123` |

### Professor (5 demo professors)
| Email | Password |
|-------|----------|
| `rajesh.sharma@cse.com` | `password123` |
| `sneha.gupta@cse.com` | `password123` |
| `amit.verma@cse.com` | `password123` |
| `priya.das@cse.com` | `password123` |
| `vikram.singh@cse.com` | `password123` |

### Student (105 demo students)
| Field | Pattern |
|-------|---------|
| Enrollment No | `11111` to `11215` |
| Password | `pass` + enrollment no (e.g., `pass11111`) |

**Example:** Enrollment: `11111`, Password: `pass11111`

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point with Firebase init
├── role_selection_screen.dart   # Role selection (Admin/Prof/HOD/Student)
│
├── admin/                       # Admin Module
│   ├── models/                  # Admin-specific models
│   ├── screens/                 # Admin dashboard, manage professors/subjects/HODs
│   └── services/                # Firestore CRUD service
│
├── hod/                         # HOD Module
│   └── screens/                 # HOD dashboard, leave approval
│
├── student/                     # Student Module
│   └── screens/                 # Student dashboard, attendance reports, leave
│
├── screens/                     # Professor Module (main screens)
│   ├── professor_login_screen.dart
│   ├── home_screen.dart         # Professor dashboard
│   ├── attendance_screen.dart   # Mark attendance
│   ├── reports_screen.dart      # Attendance reports
│   ├── timetable_screen.dart    # Manage timetable
│   └── splash_screen.dart       # Splash screen
│
├── models/                      # Shared data models
│   ├── student_model.dart
│   ├── professor_model.dart
│   ├── subject_model.dart
│   ├── attendance_model.dart
│   ├── attendance_session_model.dart
│   ├── course_model.dart
│   ├── leave_request_model.dart
│   └── ... (14 models total)
│
├── providers/                   # State management (Provider)
│   ├── attendance_provider.dart
│   ├── class_provider.dart
│   ├── student_provider.dart
│   ├── timetable_provider.dart
│   └── leave_provider.dart
│
├── database/                    # SQLite local database
│   └── database_helper.dart     # All local CRUD operations
│
├── services/                    # Utility services
│   └── excel_service.dart       # Excel import/export
│
├── utils/                       # Utilities
│   └── demo_data_seeder.dart    # Auto-seeds demo data on first run
│
└── widgets/                     # Reusable UI widgets
```

---

## ✨ Key Features

### 🔴 Admin Panel
- Manage Professors (CRUD with subject assignments)
- Manage Subjects (Core + Elective with groups)
- Manage HODs
- Manage Divisions (A/B per semester)
- Manage Courses (B.Tech CSE, MCA, etc.)

### 🔵 Professor Module
- Mark attendance for assigned classes
- View attendance reports with charts
- Manage weekly timetable
- **4-hour edit lock** — attendance auto-locks after 4 hours
- Export reports as CSV

### 🟢 HOD Module
- Department-wide attendance overview
- Approve/Reject student leave requests
- View reports across all professors and subjects

### 🟠 Student Module
- View personal attendance (subject-wise)
- Select elective subjects
- Apply for leave with date range
- View attendance history with charts

### 🔄 Hybrid Storage
- **SQLite** — Primary offline storage for fast attendance marking
- **Firebase Firestore** — Cloud sync for cross-device data access
- Auto-sync on startup

---

## 📊 Database Schema

### Firestore Collections
| Collection | Purpose |
|-----------|---------|
| `courses` | B.Tech, MCA, etc. |
| `subjects` | Core + elective subjects per semester |
| `students` | Student profiles with elective selections |
| `professors` | Professor profiles with subject assignments |
| `hods` | HOD profiles |
| `divisions` | Class divisions (A/B) |
| `attendance_sessions` | Attendance records with student details |
| `timetables` | Professor weekly timetables |

### SQLite Tables
| Table | Purpose |
|-------|---------|
| `students` | Local student data for login |
| `subjects` | Local subject cache |
| `attendance_sessions` | Local attendance sessions |
| `attendance` | Individual attendance records |
| `classes` | Professor class entries |
| `timetable` | Local timetable |
| `leave_requests` | Student leave requests |
| `student_subject_mapping` | Elective selections |

---

## 🔧 Troubleshooting

### App crashes on launch
- Make sure `google-services.json` is in `android/app/`
- Make sure Firestore Database is **enabled** in Firebase Console

### Build fails with Gradle errors
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### First launch is slow
This is normal — the `DemoDataSeeder` is creating 100+ students, subjects, professors, and 2 months of attendance history in Firestore. Subsequent launches will be fast.

### "Firebase not initialized" error
Ensure you have:
1. `google-services.json` in `android/app/`
2. Firebase Firestore enabled in test mode
3. Internet connection on first run

---

## 📝 Notes for Developers

- **Passwords are stored in plain text** — This is a demo/academic project. For production, implement proper hashing (bcrypt/argon2).
- **Admin & HOD credentials are hardcoded** — See `admin_login_screen.dart` and `hod_login_screen.dart`. For production, move to Firestore-based auth.
- **Demo data auto-seeds once** — The seeder checks if data already exists before inserting. To re-seed, clear the Firestore collections manually.
- **Material 3 Dark Theme** — The app uses a custom dark theme with deep indigo-purple accent (`#6C63FF`).

---

## 📄 License

This project is developed for academic/educational purposes as part of the CSE Department Attendance Management System initiative.
