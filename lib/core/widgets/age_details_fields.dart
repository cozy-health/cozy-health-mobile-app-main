import 'package:flutter/material.dart';
import 'country_options.dart';

class AgeDetailsFields extends StatelessWidget {
  const AgeDetailsFields({
    super.key,
    required this.dob,
    required this.country,
    required this.onChanged,
    this.enabled = true,
    this.dobError,
    this.countryError,
  });
  final TextEditingController dob, country;
  final VoidCallback onChanged;
  final bool enabled;
  final String? dobError, countryError;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        controller: dob,
        readOnly: true,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: 'Date of birth',
          helperText: 'Used to apply age and guardian requirements.',
          suffixIcon: const Icon(Icons.calendar_today_outlined),
          errorText: dobError,
          errorMaxLines: 3,
        ),
        onTap: () async {
          final now = DateTime.now().toUtc();
          final selected = await showDatePicker(
            context: context,
            initialDate: DateTime(now.year - 18, now.month, now.day),
            firstDate: DateTime(1900),
            lastDate: DateTime(now.year, now.month, now.day - 1),
          );
          if (selected == null || !context.mounted) return;
          dob.text =
              '${selected.year.toString().padLeft(4, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
          onChanged();
        },
      ),
      const SizedBox(height: 20),
      ResidenceCountryField(
        country: country,
        enabled: enabled,
        errorText: countryError,
        onChanged: onChanged,
      ),
    ],
  );
}

class ResidenceCountryField extends StatelessWidget {
  const ResidenceCountryField({
    super.key,
    required this.country,
    required this.onChanged,
    this.enabled = true,
    this.errorText,
  });
  final TextEditingController country;
  final VoidCallback onChanged;
  final bool enabled;
  final String? errorText;
  @override
  Widget build(BuildContext context) => DropdownMenu<String>(
    enabled: enabled,
    enableFilter: true,
    enableSearch: true,
    requestFocusOnTap: true,
    menuHeight: 320,
    trailingIcon: const Icon(
      Icons.arrow_drop_down,
      semanticLabel: 'Show country list',
    ),
    selectedTrailingIcon: const Icon(
      Icons.arrow_drop_up,
      semanticLabel: 'Close country list',
    ),
    expandedInsets: EdgeInsets.zero,
    label: const Text('Country of residence'),
    helperText: 'Availability depends on local requirements.',
    errorText: errorText,
    dropdownMenuEntries: residenceCountries.entries
        .map((entry) => DropdownMenuEntry(value: entry.key, label: entry.value))
        .toList(),
    onSelected: (value) {
      if (value != null) {
        country.text = value;
        onChanged();
      }
    },
  );
}
