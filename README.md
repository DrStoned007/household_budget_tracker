# Agent Instruction: HomeBudget Tracker (Flutter App)

## Overview

You are assigned to develop a mobile application called **HomeBudget Tracker** using **Flutter**. This app will allow users to:

- Track income and expense transactions
- View their financial summary in a dashboard
- Set and manage monthly budgets
- Visualize data using pie and bar charts

This app must store data **locally using Hive** and display dashboards using **fl_chart**.

---

## Technology Stack

- **Flutter** (latest stable version)
- **Dart**
- **Hive** (local data storage)
- **fl_chart** (charts and graphs)
- **Provider** or `ChangeNotifier` (for state management)

---

## Folder Structure (Must be followed)

```
lib/
├── main.dart
├── hive_setup/
│   └── hive_config.dart
├── models/
│   └── transaction_model.dart
├── pages/
│   ├── dashboard/
│   │   └── dashboard_page.dart
│   ├── transactions/
│   │   ├── transactions_page.dart      <-- To be implemented
│   │   └── add_transaction_page.dart   <-- To be implemented
│   └── budget/
│       └── budget_page.dart            <-- Optional
├── services/
│   └── transaction_service.dart        <-- To be implemented
├── providers/
│   └── transaction_provider.dart       <-- To be implemented
├── core/
│   ├── constants/
│   │   └── app_colors.dart             <-- Optional
│   ├── helpers/
│   │   └── date_utils.dart             <-- Optional
│   └── widgets/
│       └── pie_chart_widget.dart       <-- Optional
```

---

## Requirements

### 1. Hive Setup

- Initialize Hive in `hive_config.dart`
- Register and open a box for `TransactionModel`
- Include adapter generation (`transaction_model.g.dart`)

### 2. Data Model

**File**: `transaction_model.dart`

```dart
@HiveType(typeId: 0)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense
}

@HiveType(typeId: 1)
class TransactionModel extends HiveObject {
  @HiveField(0)
  String category;

  @HiveField(1)
  double amount;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  TransactionType type;

  @HiveField(4)
  String? note;

  TransactionModel({
    required this.category,
    required this.amount,
    required this.date,
    required this.type,
    this.note,
  });
}
```

> 🛠️ After creating this file, run:
```bash
flutter packages pub run build_runner build
```

---

### 3. `main.dart` Entry Point

- Initialize Hive via `HiveConfig.init()`
- Use `DashboardPage` as the initial page

---

### 4. Dashboard Page

**File**: `dashboard_page.dart`

- Show total income, total expense
- Show pie chart of expenses by category using `fl_chart`
- Pull data from Hive transactions box

---

### 5. Pages to be Implemented

#### `transactions_page.dart`
- Show a list of transactions from Hive
- Include filters (optional)

#### `add_transaction_page.dart`
- Form to add new income or expense
- Store data in Hive on submission

#### `budget_page.dart` (optional)
- Set monthly budget per category
- Compare actual expenses to the budget

---

### 6. Charts

Use `fl_chart`:
- PieChart in dashboard for expenses by category
- BarChart (optional) for monthly trend

---

### 7. State Management

Use `Provider` or `ChangeNotifier` to manage:
- Transactions list state
- Budget updates
- Refreshing UI on new data

---

### 8. UI Focus

#### Dashboard Widgets
- `summary_card.dart`: Displays totals with icon and background color  
- `pie_chart_widget.dart`: Pie chart for category breakdown (uses `fl_chart`)  
- `month_picker_dropdown.dart`: Dropdown for selecting the month filter  

#### Transaction Widgets
- `transaction_tile.dart`: Custom list tile per transaction showing title, amount, date and category.
- `category_selector.dart`: Dropdown or chip-based category selector.

---

## Testing

- Ensure you can:
  - Add transactions
  - View dashboard with summary and pie chart
  - Restart app and retain data (Hive persistence)

---

## Dependencies in `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  fl_chart: ^0.55.2
  path_provider: ^2.1.2
  provider: ^6.1.1
  intl: ^0.18.1

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.8
```

## Summary of Agent Deliverables

| Task | Description |
|------|-------------|
| Setup Hive | Config file + transaction model with adapter |
| Dashboard UI | Summary text + pie chart with fl_chart |
| Transaction List Page | ListView of all transactions |
| Add Transaction Page | Input form with dropdowns, date picker |
| State Management | Refresh dashboard on data change |
| Budget Page (Optional) | Set & compare monthly budget |

---

## Note for Developer
- This file will be continuously updated as features evolve. Stick to modular and clean architecture.
- Always run `build_runner` after changing Hive models  
- When adding new pages, register them in the navigation routes file  
- **UI Requirement**:  
  - All screens must follow **modern design principles** (clean layout, intuitive navigation, consistent theme)  
  - UI must be **responsive** across small, medium, and large devices — test on multiple screen sizes  
  - Use Flutter’s `LayoutBuilder`, `MediaQuery`, and adaptive widgets to ensure correct scaling  
  - Ensure color contrast, typography, and iconography remain accessible and visually appealing  

If anything is unclear, refer to the sample implementation already in the code or request clarification.
