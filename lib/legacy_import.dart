import 'dart:convert';

import 'models.dart';

class LegacyImport {
  LegacyImport._();

  static FinanceData parse(String text) {
    final trimmed = text.trimLeft();
    if (trimmed.startsWith('{')) {
      return FinanceData.fromJson(Map<String, dynamic>.from(jsonDecode(text) as Map));
    }
    return _parseProperties(text);
  }

  static FinanceData _parseProperties(String text) {
    final props = <String, String>{};
    final logical = <String>[];
    var current = '';
    for (final raw in text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n')) {
      if (current.isEmpty) {
        current = raw;
      } else {
        current += raw;
      }
      var slashCount = 0;
      for (var i = current.length - 1; i >= 0 && current[i] == '\\'; i--) {
        slashCount++;
      }
      if (slashCount.isOdd) {
        current = current.substring(0, current.length - 1);
        continue;
      }
      logical.add(current);
      current = '';
    }
    if (current.isNotEmpty) logical.add(current);

    for (var line in logical) {
      line = line.trimLeft();
      if (line.isEmpty || line.startsWith('#') || line.startsWith('!')) continue;
      var split = -1;
      var escaped = false;
      for (var i = 0; i < line.length; i++) {
        final c = line[i];
        if (!escaped && (c == '=' || c == ':' || c == ' ' || c == '\t')) {
          split = i;
          break;
        }
        if (c == '\\' && !escaped) {
          escaped = true;
        } else {
          escaped = false;
        }
      }
      final key = _unescape(split < 0 ? line : line.substring(0, split).trimRight());
      var value = split < 0 ? '' : line.substring(split + 1).trimLeft();
      if (value.startsWith('=') || value.startsWith(':')) value = value.substring(1).trimLeft();
      props[key] = _unescape(value);
    }

    int asInt(String? value, [int fallback = 0]) => int.tryParse(value ?? '') ?? fallback;
    bool asBool(String? value, [bool fallback = false]) {
      if (value == null) return fallback;
      return value.toLowerCase() == 'true' || value == '1' || value.toLowerCase() == 'yes';
    }
    List<int> ids(String key) => (props[key] ?? '')
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toList();

    final categories = <Category>[];
    for (final id in ids('categories')) {
      final name = props['category.$id.name']?.trim() ?? '';
      if (name.isNotEmpty) {
        categories.add(Category(id: id, name: name, recurring: asBool(props['category.$id.recurring'])));
      }
    }
    if (categories.isEmpty) categories.addAll(FinanceData.empty().categories);

    final incomes = <Income>[];
    for (final id in ids('incomes')) {
      final recurring = asBool(props['income.$id.recurring']);
      var series = asInt(props['income.$id.recurringSeriesId']);
      if (recurring && series == 0) series = id;
      incomes.add(Income(
        id: id,
        personId: asInt(props['income.$id.personId'], 1).clamp(1, 2).toInt(),
        month: props['income.$id.month'] ?? '2000-01',
        description: props['income.$id.description'] ?? '',
        amountCents: asInt(props['income.$id.amountCents']),
        recurring: recurring,
        recurringSeriesId: series,
      ));
    }

    final expenses = <Expense>[];
    for (final id in ids('expenses')) {
      var series = asInt(props['expense.$id.recurringSeriesId']);
      final categoryId = asInt(props['expense.$id.categoryId'], categories.first.id);
      final categoryRecurring = categories.where((e) => e.id == categoryId).firstOrNull?.recurring ?? false;
      if (categoryRecurring && series == 0) series = id;
      expenses.add(Expense(
        id: id,
        month: props['expense.$id.month'] ?? '2000-01',
        description: props['expense.$id.description'] ?? '',
        categoryId: categoryId,
        amountCents: asInt(props['expense.$id.amountCents']),
        person1ShareMilliPercent: asInt(props['expense.$id.person1ShareMilliPercent'], 50000).clamp(0, 100000).toInt(),
        recurringSeriesId: series,
      ));
    }

    final maxCategory = categories.fold<int>(0, (m, e) => e.id > m ? e.id : m);
    final maxIncome = incomes.fold<int>(0, (m, e) => e.id > m ? e.id : m);
    final maxExpense = expenses.fold<int>(0, (m, e) => e.id > m ? e.id : m);

    return FinanceData(
      persons: [
        Person(id: 1, name: (props['person.1.name'] ?? 'Person 1').trim()),
        Person(id: 2, name: (props['person.2.name'] ?? 'Person 2').trim()),
      ],
      categories: categories,
      incomes: incomes,
      expenses: expenses,
      nextCategoryId: maxCategory + 1,
      nextIncomeId: maxIncome + 1,
      nextExpenseId: maxExpense + 1,
    );
  }

  static String _unescape(String input) {
    final out = StringBuffer();
    for (var i = 0; i < input.length; i++) {
      final c = input[i];
      if (c != '\\' || i + 1 >= input.length) {
        out.write(c);
        continue;
      }
      final n = input[++i];
      switch (n) {
        case 't': out.write('\t'); break;
        case 'n': out.write('\n'); break;
        case 'r': out.write('\r'); break;
        case 'f': out.write('\f'); break;
        case 'u':
          if (i + 4 < input.length) {
            final hex = input.substring(i + 1, i + 5);
            final value = int.tryParse(hex, radix: 16);
            if (value != null) {
              out.writeCharCode(value);
              i += 4;
            } else {
              out.write('u');
            }
          } else {
            out.write('u');
          }
          break;
        default: out.write(n);
      }
    }
    return out.toString();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
