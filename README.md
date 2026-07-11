# Campus Connect

Live Web App: [ccstudent.99practice.com](https://ccstudent.99practice.com)

Welcome to the repository for **Campus Connect**, a comprehensive Flutter application designed to keep students updated with the latest campus events and notices. This README provides a complete overview of the app's features, architecture, and technology stack, submitted as part of the DevSoc society selection task.

---

## 🚀 Key Features

* **Dedicated Feeds:** Separate, intuitive tabs for both campus notices and upcoming events.
* **Detailed Views:** In-depth pages for events and notices showcasing important links, detailed descriptions, organizers, dates, and venues.
* **Offline Support:** Smart caching mechanism using `SharedPreferences` that locally saves data, allowing users to view feeds even without an internet connection.
* **Robust Search Engine:** Full-screen search functionality with API debouncing, categorized results (Events, Notices, Bookmarks), and a saved recent search history.
* **Bookmark System:** Save favorite events and notices for quick access, complete with a floating "Undo" SnackBar if an item is accidentally removed.
* **Cross-Platform Wrapper:** A custom `DesktopMobileWrapper` that detects desktop environments (Windows, macOS, Linux) and scales a logical mobile view (iPhone 14 Pro Max proportions) to 75% for seamless desktop testing.
* **Smooth UI/UX:** Integration of `Skeletonizer` for modern loading states, `CachedNetworkImage` for efficient image rendering, and fluid hero animations for search bar transitions.

---

## 🛠️ Technology Stack

* **Framework:** Flutter (Dart).
* **State Management:** Riverpod (`flutter_riverpod`) for managing search states and API data.
* **Local Storage:** `shared_preferences` for caching API responses, saving search history, and storing bookmarked IDs locally.
* **Networking:** `http` package for connecting to the custom REST API hosted on Render (`[https://campus-connect-api-z6og.onrender.com](https://campus-connect-api-z6og.onrender.com)`).
* **External Integrations:** `url_launcher` for safely opening external registration and important links directly from the app.

---

## 📁 Project Structure

The codebase is modularized for maintainability and scalability:

* **`/models`**: Contains the data classes (`Event` and `Notice`) with structured JSON serialization.
* **`/providers`**: Houses the Riverpod notifiers (`SearchState`, `BaseSearchNotifier`, etc.) to handle decoupled business logic.
* **`/services`**: Contains `ApiService` which manages asynchronous HTTP GET requests and handles caching fallbacks.
* **`/screens`**: Holds all UI page views including `MainNav` (Bottom Navigation), `NoticesFeed`, `EventsFeed`, `BookmarksScreen`, and their respective detail screens.
* **`/widgets`**: Stores reusable UI components like the `CustomHeader`.

---

## ⚙️ Core Mechanisms Explained

* **Smart Fetching:** When the feed screens load, the app attempts to fetch live data from the API. If it fails (e.g., due to no internet connection), it seamlessly retrieves the last saved JSON response from `SharedPreferences` and alerts the user via a SnackBar.
* **Debounced Search:** To prevent spamming the backend, the search provider uses a `Timer` to implement a 500ms debounce before dispatching the query to the server.
* **Link Handling:** The application automatically cleans up external URLs fetched from the backend (adding `https://` if missing) and launches them safely in an external browser mode.
