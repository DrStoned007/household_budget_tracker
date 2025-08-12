# HomeBudget Tracker

HomeBudget Tracker is a Flutter-based mobile application designed to help you manage your personal finances with ease. Track your income and expenses, set monthly budgets, and gain insights into your spending habits through intuitive charts and summaries.

## 🚀 Features

*   **Transaction Management:** Easily add, edit, and delete your income and expense transactions.
*   **Budgeting:** Set monthly budgets for different categories and monitor your spending to stay on track.
*   **Data Visualization:** Visualize your financial data with interactive pie charts that show your expense breakdown by category.
*   **Dashboard:** Get a quick overview of your financial health on the dashboard, which displays your total income, expenses, and budget summaries.
*   **Local Storage:** All your financial data is stored securely on your device using Hive, ensuring privacy and offline access.
*   **Notifications:** Receive alerts for budget overspending and daily reminders to add your transactions.

## 🛠️ Technologies Used

*   **Flutter:** The UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase.
*   **Dart:** The programming language used for Flutter development.
*   **Hive:** A lightweight and fast key-value database for local storage.
*   **fl_chart:** A powerful library for creating beautiful charts and graphs.
*   **Provider:** A state management solution for Flutter applications.
*   **flutter_local_notifications:** A plugin for displaying local notifications.

## 🏁 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

*   [Flutter SDK](https://flutter.dev/docs/get-started/install) (latest stable version)
*   An editor like [Android Studio](https://developer.android.com/studio) or [Visual Studio Code](https://code.visualstudio.com/) with the Flutter plugin.

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/household_budget_tracker.git
    cd household_budget_tracker
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Run the build runner:**
    This step is necessary to generate the Hive type adapters.
    ```bash
    flutter packages pub run build_runner build
    ```
4.  **Run the app:**
    ```bash
    flutter run
    ```

## 📂 Project Structure

The project follows a feature-based folder structure to keep the codebase organized and maintainable.

```
lib/
├── core/              # Core widgets, helpers, and constants
├── data/              # Data models and services
├── pages/             # UI screens for different features
│   ├── dashboard/
│   ├── transactions/
│   └── budget/
├── providers/         # State management using Provider
├── main.dart          # The entry point of the application
```

## 🤝 Contributing

Contributions are welcome! If you have any ideas, suggestions, or bug reports, please open an issue or submit a pull request.

1.  **Fork the repository.**
2.  **Create a new branch:** `git checkout -b feature-or-bugfix-name`
3.  **Make your changes.**
4.  **Commit your changes:** `git commit -m 'Add some feature'`
5.  **Push to the branch:** `git push origin feature-or-bugfix-name`
6.  **Open a pull request.**

---
