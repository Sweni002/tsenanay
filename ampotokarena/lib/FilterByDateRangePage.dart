import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class FilterByDateRangePage extends StatefulWidget {
  const FilterByDateRangePage({Key? key}) : super(key: key);

  @override
  State<FilterByDateRangePage> createState() => _FilterByDateRangePageState();
}

class _FilterByDateRangePageState extends State<FilterByDateRangePage> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));

  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
    _updateTextFields();
  }

  void _updateTextFields() {
    _startController.text = DateFormat('dd MMM yyyy', 'fr_FR').format(_startDate);
    _endController.text = DateFormat('dd MMM yyyy', 'fr_FR').format(_endDate);
  }

  Future<void> _pickDate({required bool isStart}) async {
    DateTime tempDate = isStart ? _startDate : _endDate;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TableCalendar(
              locale: 'fr_FR',
              firstDay: DateTime(2020),
              lastDay: DateTime(2100),
              focusedDay: tempDate,
              selectedDayPredicate: (day) => day == tempDate,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  if (isStart) {
                    _startDate = selectedDay;
                    if (_startDate.isAfter(_endDate)) _endDate = _startDate;
                  } else {
                    _endDate = selectedDay;
                    if (_endDate.isBefore(_startDate)) _startDate = _endDate;
                  }
                  _updateTextFields();
                });
                Navigator.pop(context);
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.teal,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyFilter() {
    Navigator.pop(context, {'startDate': _startDate, 'endDate': _endDate});
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Filtrer entre deux dates")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _startController,
              readOnly: true,
              onTap: () => _pickDate(isStart: true),
              decoration: InputDecoration(
                labelText: "Date de début",
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _endController,
              readOnly: true,
              onTap: () => _pickDate(isStart: false),
              decoration: InputDecoration(
                labelText: "Date de fin",
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _applyFilter,
              child: const Text("Appliquer le filtre"),
            ),
          ],
        ),
      ),
    );
  }
}
