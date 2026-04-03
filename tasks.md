# Phone-Link Project Tasks

## 📱 Mobile Application (Flutter / Android)
- [x] **Notification Listener Service:** Implement Android platform channels or integrate a plugin (e.g., `notification_listener_service`) to intercept incoming phone notifications.
- [ ] **Permissions Management:** Add logic to request necessary Android permissions (Notification Access, Internet, Local Network).
- [ ] **Network Service Discovery (NSD):** Implement local network scanning using the `nsd` package to discover the Qt desktop application.
- [ ] **Network Communication Client:** Set up a TCP or WebSocket client to securely transmit intercepted notification data to the desktop.
- [ ] **State Management:** Configure the `provider` package to manage connection status, discovered desktop devices, and active settings.
- [ ] **UI/UX Implementation:** Replace the default Flutter counter app with the actual Phone-Link dashboard, including connection controls and settings via `shared_preferences`.
- [ ] **Testing:** Remove the default boilerplate `test/widget_test.dart` and write valid unit/widget tests for the core networking and UI logic.

## 💻 Desktop Application (Qt / C++)
- [ ] **Project Setup:** Initialize the C++/Qt project for the desktop host application.
- [ ] **NSD Broadcasting:** Implement a service to broadcast the desktop's presence on the local network so the Flutter app can discover it.
- [ ] **Socket Server:** Create a TCP or WebSocket server in Qt to listen for incoming connections and notification payloads from the phone.
- [ ] **Native Desktop Notifications:** Parse incoming notification payloads and display them using Qt's native system tray or notification APIs (`QSystemTrayIcon` / `QNotification`).
- [ ] **Desktop UI:** Create a system tray menu and a dashboard for managing paired devices and notification preferences.

## 🔗 Core Integration & Security
- [ ] **Define Communication Protocol:** Design a standardized JSON schema for notification payloads (e.g., App Name, Title, Content, Icon).
- [ ] **Pairing Mechanism:** Implement a secure pairing flow (e.g., PIN matching or QR code scanning) to ensure the phone only sends data to the trusted laptop.
- [ ] **End-to-End Encryption:** Encrypt the socket communication over the local network to protect sensitive notification data.
- [ ] **Background Execution:** Ensure the Flutter app can run in the background on Android to continuously monitor notifications when the app is closed.
- [ ] **Error Handling & Reconnection:** Add robust handling for network drops, Wi-Fi disconnections (using `connectivity_plus`), and automatic reconnections.