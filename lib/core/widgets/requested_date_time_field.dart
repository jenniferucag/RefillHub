import 'package:flutter/material.dart';

class RequestedDateTimeField extends StatelessWidget {
  const RequestedDateTimeField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.mustBeAfter,
    super.key,
  });

  final String label;
  final DateTime? value;
  final DateTime? mustBeAfter;
  final ValueChanged<DateTime> onChanged;

  Future<void> _select(BuildContext context) async {
    final now = DateTime.now();
    final earliest = mustBeAfter != null && mustBeAfter!.isAfter(now)
        ? mustBeAfter!
        : now;
    final initial = value != null && value!.isAfter(earliest)
        ? value!
        : earliest;
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(initial.year, initial.month, initial.day),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !context.mounted) return;
    final requested = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final lowerBound = mustBeAfter == null || now.isAfter(mustBeAfter!)
        ? now
        : mustBeAfter!;
    if (!requested.isAfter(lowerBound)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mustBeAfter == null
                ? 'Choose a requested time in the future.'
                : 'Choose a time after the preceding requested time.',
          ),
        ),
      );
      return;
    }
    onChanged(requested);
  }

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? 'Select requested date and time'
        : '${value!.year}-${value!.month.toString().padLeft(2, '0')}-'
              '${value!.day.toString().padLeft(2, '0')} '
              '${TimeOfDay.fromDateTime(value!).format(context)}';
    return OutlinedButton.icon(
      onPressed: () => _select(context),
      icon: const Icon(Icons.calendar_today_outlined),
      label: Text('$label: $text', textAlign: TextAlign.center),
    );
  }
}
