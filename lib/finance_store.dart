import 'dart:convert';

import 'package:flutter/foundation.dart' hide Category;
import 'package:shared_preferences/shared_preferences.dart';

import 'formatters.dart';
import 'legacy_import.dart';
import 'models.dart';

class FinanceStore extends ChangeNotifier {
  static const _stateKey = 'paarfinanzen_state_v4';
  static const _beforeImportKey = 'paarfinanzen_before_last_import';

  late SharedPreferences _prefs;
  FinanceData _data = FinanceData.empty();
  String selectedMonth = MonthKey.current();
  FinanceView view = FinanceView.common;

  FinanceData get data => _data;
  List<Person> get persons => List.unmodifiable(_data.persons);
  List<Category> get categories => List.unmodifiable(_data.categories);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_stateKey);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        _data = FinanceData.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
      } catch (_) {
        _data = FinanceData.empty();
      }
    }
    await ensureRecurringForMonth(selectedMonth, notify: false);
  }

  String personName(int id) => _data.persons.where((e) => e.id == id).map((e) => e.name).firstOrNull ?? 'Person $id';
  Category? categoryById(int id) => _data.categories.where((e) => e.id == id).firstOrNull;
  String categoryName(int id) => categoryById(id)?.name ?? 'Unbekannt';

  List<Income> incomesForMonth([String? month]) {
    final m = month ?? selectedMonth;
    final list = _data.incomes.where((e) => e.month == m).toList();
    list.sort((a, b) => a.description.toLowerCase().compareTo(b.description.toLowerCase()));
    return list;
  }

  List<Expense> expensesForMonth([String? month]) {
    final m = month ?? selectedMonth;
    final list = _data.expenses.where((e) => e.month == m).toList();
    list.sort((a, b) => a.description.toLowerCase().compareTo(b.description.toLowerCase()));
    return list;
  }

  int incomeValue(Income income, [FinanceView? forView]) {
    switch (forView ?? view) {
      case FinanceView.common: return income.amountCents;
      case FinanceView.person1: return income.personId == 1 ? income.amountCents : 0;
      case FinanceView.person2: return income.personId == 2 ? income.amountCents : 0;
    }
  }

  int expenseValue(Expense expense, [FinanceView? forView]) {
    switch (forView ?? view) {
      case FinanceView.common: return expense.amountCents;
      case FinanceView.person1: return Money.share(expense.amountCents, expense.person1ShareMilliPercent);
      case FinanceView.person2: return expense.amountCents - Money.share(expense.amountCents, expense.person1ShareMilliPercent);
    }
  }

  int get totalIncome => incomesForMonth().fold(0, (sum, e) => sum + incomeValue(e));
  int get totalExpenses => expensesForMonth().fold(0, (sum, e) => sum + expenseValue(e));
  int get available => totalIncome - totalExpenses;
  double get remainingRate => totalIncome <= 0 ? 0 : ((available / totalIncome) * 100).clamp(0, 999).toDouble();

  Map<Category, int> categoryTotals() {
    final out = <Category, int>{};
    for (final expense in expensesForMonth()) {
      final category = categoryById(expense.categoryId);
      if (category == null) continue;
      out[category] = (out[category] ?? 0) + expenseValue(expense);
    }
    final entries = out.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries);
  }

  Future<void> setMonth(String month) async {
    selectedMonth = month;
    await ensureRecurringForMonth(month, notify: false);
    notifyListeners();
  }

  Future<void> changeMonth(int delta) => setMonth(MonthKey.add(selectedMonth, delta));
  void setView(FinanceView next) { view = next; notifyListeners(); }

  Future<void> renamePerson(int id, String name) async {
    final index = _data.persons.indexWhere((e) => e.id == id);
    if (index < 0) return;
    final cleaned = name.trim().isEmpty ? 'Person $id' : name.trim();
    _data.persons[index] = _data.persons[index].copyWith(name: cleaned);
    await _save();
  }

  Future<void> addIncome({required int personId, required String month, required String description, required int amountCents, required bool recurring}) async {
    final id = _data.nextIncomeId++;
    _data.incomes.add(Income(
      id: id,
      personId: personId,
      month: month,
      description: description.trim(),
      amountCents: amountCents,
      recurring: recurring,
      recurringSeriesId: recurring ? id : 0,
    ));
    await _save();
  }

  Future<void> updateIncome(Income old, {required int personId, required String month, required String description, required int amountCents, required bool recurring}) async {
    final index = _data.incomes.indexWhere((e) => e.id == old.id);
    if (index < 0) return;
    final series = old.recurringSeriesId != 0 ? old.recurringSeriesId : (recurring ? old.id : 0);
    _data.incomes[index] = old.copyWith(personId: personId, month: month, description: description.trim(), amountCents: amountCents, recurring: recurring, recurringSeriesId: series);
    await _save();
  }

  Future<void> deleteIncome(Income income) async {
    if (income.recurringSeriesId != 0) _data.incomeRecurrenceSkips.add('${income.recurringSeriesId}@${income.month}');
    _data.incomes.removeWhere((e) => e.id == income.id);
    await _save();
  }

  Future<void> addExpense({required String month, required String description, required int categoryId, required int amountCents, required int person1ShareMilliPercent}) async {
    final id = _data.nextExpenseId++;
    final recurring = categoryById(categoryId)?.recurring ?? false;
    _data.expenses.add(Expense(
      id: id,
      month: month,
      description: description.trim(),
      categoryId: categoryId,
      amountCents: amountCents,
      person1ShareMilliPercent: person1ShareMilliPercent,
      recurringSeriesId: recurring ? id : 0,
    ));
    await _save();
  }

  Future<void> updateExpense(Expense old, {required String month, required String description, required int categoryId, required int amountCents, required int person1ShareMilliPercent}) async {
    final index = _data.expenses.indexWhere((e) => e.id == old.id);
    if (index < 0) return;
    final recurring = categoryById(categoryId)?.recurring ?? false;
    final series = old.recurringSeriesId != 0 ? old.recurringSeriesId : (recurring ? old.id : 0);
    _data.expenses[index] = old.copyWith(month: month, description: description.trim(), categoryId: categoryId, amountCents: amountCents, person1ShareMilliPercent: person1ShareMilliPercent, recurringSeriesId: series);
    await _save();
  }

  Future<void> deleteExpense(Expense expense) async {
    if (expense.recurringSeriesId != 0) _data.expenseRecurrenceSkips.add('${expense.recurringSeriesId}@${expense.month}');
    _data.expenses.removeWhere((e) => e.id == expense.id);
    await _save();
  }

  Future<void> addCategory(String name, bool recurring) async {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return;
    _data.categories.add(Category(id: _data.nextCategoryId++, name: cleaned, recurring: recurring));
    await _save();
  }

  Future<void> updateCategory(Category old, String name, bool recurring) async {
    final index = _data.categories.indexWhere((e) => e.id == old.id);
    if (index < 0 || name.trim().isEmpty) return;
    _data.categories[index] = old.copyWith(name: name.trim(), recurring: recurring);
    await _save();
  }

  Future<bool> deleteCategory(Category category) async {
    if (_data.expenses.any((e) => e.categoryId == category.id)) return false;
    _data.categories.removeWhere((e) => e.id == category.id);
    await _save();
    return true;
  }

  Future<void> ensureRecurringForMonth(String month, {bool notify = true}) async {
    var changed = false;
    final seriesIds = _data.incomes.map((e) => e.recurringSeriesId).where((e) => e != 0).toSet();
    for (final series in seriesIds) {
      if (_data.incomeRecurrenceSkips.contains('$series@$month')) continue;
      if (_data.incomes.any((e) => e.recurringSeriesId == series && e.month == month)) continue;
      final prior = _data.incomes.where((e) => e.recurringSeriesId == series && e.month.compareTo(month) < 0).toList()..sort((a, b) => b.month.compareTo(a.month));
      if (prior.isEmpty || !prior.first.recurring) continue;
      final src = prior.first;
      _data.incomes.add(Income(id: _data.nextIncomeId++, personId: src.personId, month: month, description: src.description, amountCents: src.amountCents, recurring: true, recurringSeriesId: series));
      changed = true;
    }

    final expenseSeries = _data.expenses.map((e) => e.recurringSeriesId).where((e) => e != 0).toSet();
    for (final series in expenseSeries) {
      if (_data.expenseRecurrenceSkips.contains('$series@$month')) continue;
      if (_data.expenses.any((e) => e.recurringSeriesId == series && e.month == month)) continue;
      final prior = _data.expenses.where((e) => e.recurringSeriesId == series && e.month.compareTo(month) < 0).toList()..sort((a, b) => b.month.compareTo(a.month));
      if (prior.isEmpty) continue;
      final src = prior.first;
      if (!(categoryById(src.categoryId)?.recurring ?? false)) continue;
      _data.expenses.add(Expense(id: _data.nextExpenseId++, month: month, description: src.description, categoryId: src.categoryId, amountCents: src.amountCents, person1ShareMilliPercent: src.person1ShareMilliPercent, recurringSeriesId: series));
      changed = true;
    }
    if (changed) await _save(notify: false);
    if (notify) notifyListeners();
  }

  Future<String> exportJson() async => _data.toPrettyJson();

  Future<void> importText(String text) async {
    final old = jsonEncode(_data.toJson());
    final imported = LegacyImport.parse(text);
    await _prefs.setString(_beforeImportKey, old);
    _data = imported;
    await ensureRecurringForMonth(selectedMonth, notify: false);
    await _save();
  }

  bool get canUndoImport => _prefs.getString(_beforeImportKey) != null;
  Future<bool> undoLastImport() async {
    final raw = _prefs.getString(_beforeImportKey);
    if (raw == null) return false;
    _data = FinanceData.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    await _prefs.remove(_beforeImportKey);
    await _save();
    return true;
  }

  Future<void> reset() async {
    _data = FinanceData.empty();
    selectedMonth = MonthKey.current();
    view = FinanceView.common;
    await _prefs.remove(_beforeImportKey);
    await _save();
  }

  Future<void> _save({bool notify = true}) async {
    await _prefs.setString(_stateKey, jsonEncode(_data.toJson()));
    if (notify) notifyListeners();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
