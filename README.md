# EventSphere Project

EventSphere is separated into two clean components: the Flutter-based user interface (`frontend`) and the Firebase configuration and automated test suite (`backend`).

## Project Structure
```
event/
├── frontend/                  # Flutter Web/Mobile Application
│   ├── lib/                   # Flutter source code
│   ├── assets/                # App asset files (images, icons)
│   ├── test/                  # Flutter unit & widget tests
│   ├── frontend_test/         # E2E simulated frontend test runner
│   ├── apium testing/         # Appium end-to-end integration tests
│   └── pubspec.yaml           # Flutter dependencies configuration
│
└── backend/                   # Firebase configuration and backend tests
    ├── firestore.rules        # Security rules for Firestore
    ├── firestore.indexes.json # Custom query indexes for Firestore
    └── automated_test/        # E2E simulated backend test runner
```

## Frontend Setup
To run the frontend Flutter application:
```bash
cd frontend
flutter pub get
flutter run
```

## Testing

### Backend Security and Rules Testing
To execute backend API and rule simulations:
```bash
python backend/automated_test/backend_test_runner.py
```
This generates an Excel report spreadsheet under `backend/automated_test/`.

### Frontend Flow Verification
To execute frontend E2E widget test simulations:
```bash
python frontend/frontend_test/frontend_test_runner.py
```
This generates an Excel report spreadsheet under `frontend/frontend_test/`.  