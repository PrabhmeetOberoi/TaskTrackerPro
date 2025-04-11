# Temple Management System

A comprehensive temple management system designed to track devotee attendance with Bluetooth printer integration, user authentication, and reporting features.

## Overview

This project consists of two main components:

1. **Web Application (Python Flask)**: A complete web-based system with user authentication, devotee management, and reporting dashboards.

2. **Mobile Application (Flutter)**: An Android and iOS compatible mobile app with the same functionality as the web application, with a special focus on Bluetooth printer integration.

## Features

### Common Features (Web & Mobile)

- **User Authentication**: Login, logout, and admin setup
- **Devotee Management**: Add devotees and track their visits
- **Random Item Selection**: Randomly selects 1 of 18 pre-defined items for each devotee visit
- **Dashboard**: View reports of visits daily, monthly, yearly, and by devotee
- **Print Labels**: Generate and print labels with devotee information

### Web Application Specific Features

- Built with Python Flask and SQLAlchemy for the backend
- Bootstrap-based responsive UI
- Server-side rendering with Jinja2 templates

### Mobile Application Specific Features

- Built with Flutter for cross-platform support (Android & iOS)
- Native Bluetooth connectivity for direct printer access
- Custom numeric keypad for devotee ID entry
- Offline capability with local data storage

## Technical Stack

### Web Application

- **Backend**: Python, Flask, SQLAlchemy
- **Frontend**: HTML, CSS, JavaScript
- **Database**: SQLite (can be upgraded to PostgreSQL)
- **Authentication**: Flask-Login
- **Form Handling**: Flask-WTF, WTForms

### Mobile Application

- **Framework**: Flutter
- **Language**: Dart
- **State Management**: Stateful widgets and services
- **HTTP Client**: http package
- **Bluetooth**: flutter_blue
- **Storage**: shared_preferences

## Project Structure

### Web Application

```
/
├── app.py                  # Main Flask application
├── config.py               # Configuration settings
├── database.py             # Database connection and initialization
├── models.py               # SQLAlchemy models
├── forms.py                # Flask-WTF form definitions
├── static/                 # Static assets (CSS, JS, images)
│   ├── css/                # Stylesheets
│   ├── js/                 # JavaScript files
│   └── img/                # Images
├── templates/              # Jinja2 templates
│   ├── layout.html         # Base template
│   ├── home.html           # Home page
│   ├── login.html          # Login page
│   ├── admin_setup.html    # Admin setup page
│   ├── devotee.html        # Devotee check-in page
│   ├── dashboard.html      # Dashboard page
│   └── add_devotee.html    # Add devotee page
└── utils/                  # Utility functions
    ├── printer.py          # Printer utilities
    └── report_generator.py # Report generation utilities
```

### Mobile Application

```
/
├── lib/                    # Dart source files
│   ├── main.dart           # Entry point
│   ├── models/             # Data models
│   │   ├── devotee.dart    # Devotee model
│   │   └── visit.dart      # Visit model
│   ├── screens/            # UI screens
│   │   ├── devotee_screen.dart     # Devotee check-in screen
│   │   ├── dashboard_screen.dart   # Dashboard screen
│   │   └── login_screen.dart       # Login screen
│   ├── services/           # Business logic
│   │   ├── api_service.dart        # API communication
│   │   └── bluetooth_service.dart  # Bluetooth functionality
│   └── widgets/            # Reusable UI components
│       └── numeric_keypad.dart     # Custom numeric keypad
└── pubspec.yaml            # Flutter dependencies
```

## Setup and Installation

### Web Application

1. **Install Dependencies**:
   ```bash
   pip install flask flask-login flask-sqlalchemy flask-wtf sqlalchemy email-validator
   ```

2. **Run the Application**:
   ```bash
   python app.py
   ```

3. **Access the Web Interface**:
   Open a browser and go to `http://localhost:5000`

### Mobile Application

1. **Set Up Flutter**:
   Follow the [Flutter installation guide](https://flutter.dev/docs/get-started/install)

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the Application**:
   ```bash
   flutter run
   ```

## Usage

1. **Initial Setup**:
   - Launch the application
   - Complete the admin setup process to create an administrator account

2. **Devotee Management**:
   - Log in as admin
   - Add devotees via the "Add Devotee" page

3. **Devotee Check-in**:
   - Go to the "Devotee" page
   - Enter a devotee ID
   - System will randomly select an item
   - Connect a Bluetooth printer to print a label

4. **View Reports**:
   - Log in as admin
   - Access the dashboard to view various reports

## Future Enhancements

1. **Advanced Analytics**: More detailed reports and visualizations
2. **Notification System**: SMS/Email notifications for important events
3. **QR Code Support**: QR codes for faster devotee identification
4. **Cloud Synchronization**: Real-time data sync between web and mobile apps
5. **Backup & Restore**: Automated backup and restore functionality

## License

This project is licensed under the MIT License - see the LICENSE file for details.