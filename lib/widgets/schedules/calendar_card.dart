import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarCard extends StatelessWidget {
  final DateTime selectedDate;
  final Map<DateTime, List<String>> events;
  final void Function(DateTime) onDateChanged;

  const CalendarCard({
    Key? key,
    required this.selectedDate,
    required this.events,
    required this.onDateChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: TableCalendar(
        firstDay: DateTime(2000),
        lastDay: DateTime(2100),
        focusedDay: selectedDate,
        selectedDayPredicate: (day) =>
            day.year == selectedDate.year &&
            day.month == selectedDate.month &&
            day.day == selectedDate.day,
        onDaySelected: (selected, _) => onDateChanged(selected),
        eventLoader: (day) {
          final normalized = DateTime(day.year, day.month, day.day);
          return events[normalized] ?? [];
        },
        calendarStyle: CalendarStyle(
          markerDecoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
