import 'dart:convert';

class Person {
  const Person({required this.id, required this.name});

  final int id;
  final String name;

  Person copyWith({String? name}) => Person(id: id, name: name ?? this.name);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: (json['id'] as num).toInt(),
        name: (json['name'] as String?)?.trim().isNotEmpty == true
            ? (json['name'] as String).trim()
            : 'Person ${(json['id'] as num).toInt()}',
      );
}

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.recurring,
  });

  final int id;
  final String name;
  final bool recurring;

  Category copyWith({String? name, bool? recurring}) => Category(
        id: id,
        name: name ?? this.name,
        recurring: recurring ?? this.recurring,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'recurring': recurring,
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: (json['id'] as num).toInt(),
        name: (json['name'] as String? ?? '').trim(),
        recurring: json['recurring'] as bool? ?? false,
      );
}

class Income {
  const Income({
    required this.id,
    required this.personId,
    required this.month,
    required this.description,
    required this.amountCents,
    required this.recurring,
    required this.recurringSeriesId,
  });

  final int id;
  final int personId;
  final String month;
  final String description;
  final int amountCents;
  final bool recurring;
  final int recurringSeriesId;

  Income copyWith({
    int? personId,
    String? month,
    String? description,
    int? amountCents,
    bool? recurring,
    int? recurringSeriesId,
  }) =>
      Income(
        id: id,
        personId: personId ?? this.personId,
        month: month ?? this.month,
        description: description ?? this.description,
        amountCents: amountCents ?? this.amountCents,
        recurring: recurring ?? this.recurring,
        recurringSeriesId: recurringSeriesId ?? this.recurringSeriesId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'personId': personId,
        'month': month,
        'description': description,
        'amountCents': amountCents,
        'recurring': recurring,
        'recurringSeriesId': recurringSeriesId,
      };

  factory Income.fromJson(Map<String, dynamic> json) => Income(
        id: (json['id'] as num).toInt(),
        personId: (json['personId'] as num).toInt(),
        month: json['month'] as String,
        description: (json['description'] as String? ?? '').trim(),
        amountCents: (json['amountCents'] as num).toInt(),
        recurring: json['recurring'] as bool? ?? false,
        recurringSeriesId:
            (json['recurringSeriesId'] as num?)?.toInt() ?? 0,
      );
}

class Expense {
  const Expense({
    required this.id,
    required this.month,
    required this.description,
    required this.categoryId,
    required this.amountCents,
    required this.person1ShareMilliPercent,
    required this.recurringSeriesId,
  });

  final int id;
  final String month;
  final String description;
  final int categoryId;
  final int amountCents;
  final int person1ShareMilliPercent;
  final int recurringSeriesId;

  int get person2ShareMilliPercent => 100000 - person1ShareMilliPercent;

  Expense copyWith({
    String? month,
    String? description,
    int? categoryId,
    int? amountCents,
    int? person1ShareMilliPercent,
    int? recurringSeriesId,
  }) =>
      Expense(
        id: id,
        month: month ?? this.month,
        description: description ?? this.description,
        categoryId: categoryId ?? this.categoryId,
        amountCents: amountCents ?? this.amountCents,
        person1ShareMilliPercent:
            person1ShareMilliPercent ?? this.person1ShareMilliPercent,
        recurringSeriesId: recurringSeriesId ?? this.recurringSeriesId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'month': month,
        'description': description,
        'categoryId': categoryId,
        'amountCents': amountCents,
        'person1ShareMilliPercent': person1ShareMilliPercent,
        'recurringSeriesId': recurringSeriesId,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: (json['id'] as num).toInt(),
        month: json['month'] as String,
        description: (json['description'] as String? ?? '').trim(),
        categoryId: (json['categoryId'] as num).toInt(),
        amountCents: (json['amountCents'] as num).toInt(),
        person1ShareMilliPercent:
            (json['person1ShareMilliPercent'] as num).toInt(),
        recurringSeriesId:
            (json['recurringSeriesId'] as num?)?.toInt() ?? 0,
      );
}

enum FinanceView { common, person1, person2 }

class FinanceData {
  FinanceData({
    required this.persons,
    required this.categories,
    required this.incomes,
    required this.expenses,
    required this.nextCategoryId,
    required this.nextIncomeId,
    required this.nextExpenseId,
    Set<String>? incomeRecurrenceSkips,
    Set<String>? expenseRecurrenceSkips,
  })  : incomeRecurrenceSkips = incomeRecurrenceSkips ?? <String>{},
        expenseRecurrenceSkips = expenseRecurrenceSkips ?? <String>{};

  static const schemaVersion = 4;

  final List<Person> persons;
  final List<Category> categories;
  final List<Income> incomes;
  final List<Expense> expenses;
  int nextCategoryId;
  int nextIncomeId;
  int nextExpenseId;
  final Set<String> incomeRecurrenceSkips;
  final Set<String> expenseRecurrenceSkips;

  factory FinanceData.empty() => FinanceData(
        persons: const [
          Person(id: 1, name: 'Person 1'),
          Person(id: 2, name: 'Person 2'),
        ].toList(),
        categories: const [
          Category(id: 1, name: 'Fixkosten', recurring: true),
          Category(id: 2, name: 'Variable Kosten', recurring: false),
          Category(id: 3, name: 'Sparen', recurring: false),
          Category(id: 4, name: 'Freizeit', recurring: false),
          Category(id: 5, name: 'Versicherungen', recurring: true),
        ].toList(),
        incomes: [],
        expenses: [],
        nextCategoryId: 6,
        nextIncomeId: 1,
        nextExpenseId: 1,
      );

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'persons': persons.map((e) => e.toJson()).toList(),
        'categories': categories.map((e) => e.toJson()).toList(),
        'incomes': incomes.map((e) => e.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'nextCategoryId': nextCategoryId,
        'nextIncomeId': nextIncomeId,
        'nextExpenseId': nextExpenseId,
        'incomeRecurrenceSkips': incomeRecurrenceSkips.toList()..sort(),
        'expenseRecurrenceSkips': expenseRecurrenceSkips.toList()..sort(),
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory FinanceData.fromJson(Map<String, dynamic> json) {
    final personsRaw = (json['persons'] as List<dynamic>? ?? const []);
    final categoriesRaw = (json['categories'] as List<dynamic>? ?? const []);
    final incomesRaw = (json['incomes'] as List<dynamic>? ?? const []);
    final expensesRaw = (json['expenses'] as List<dynamic>? ?? const []);

    final persons = personsRaw
        .map((e) => Person.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    while (persons.length < 2) {
      persons.add(Person(id: persons.length + 1, name: 'Person ${persons.length + 1}'));
    }

    final categories = categoriesRaw
        .map((e) => Category.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((e) => e.name.isNotEmpty)
        .toList();

    final incomes = incomesRaw
        .map((e) => Income.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final expenses = expensesRaw
        .map((e) => Expense.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final maxCategory = categories.fold<int>(0, (m, e) => e.id > m ? e.id : m);
    final maxIncome = incomes.fold<int>(0, (m, e) => e.id > m ? e.id : m);
    final maxExpense = expenses.fold<int>(0, (m, e) => e.id > m ? e.id : m);

    return FinanceData(
      persons: persons.take(2).toList(),
      categories: categories.isEmpty ? FinanceData.empty().categories : categories,
      incomes: incomes,
      expenses: expenses,
      nextCategoryId:
          ((json['nextCategoryId'] as num?)?.toInt() ?? maxCategory + 1)
              .clamp(maxCategory + 1, 1 << 31).toInt(),
      nextIncomeId: ((json['nextIncomeId'] as num?)?.toInt() ?? maxIncome + 1)
          .clamp(maxIncome + 1, 1 << 31).toInt(),
      nextExpenseId:
          ((json['nextExpenseId'] as num?)?.toInt() ?? maxExpense + 1)
              .clamp(maxExpense + 1, 1 << 31).toInt(),
      incomeRecurrenceSkips:
          Set<String>.from(json['incomeRecurrenceSkips'] as List<dynamic>? ?? const []),
      expenseRecurrenceSkips:
          Set<String>.from(json['expenseRecurrenceSkips'] as List<dynamic>? ?? const []),
    );
  }
}
