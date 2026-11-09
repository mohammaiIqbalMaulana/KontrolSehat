import 'package:flutter/material.dart';

import '../../../core/di/services.dart';
import '../../../core/utils/app_time.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/loading_button.dart';
import '../data/medication_models.dart';

/// Form tambah/ubah obat (S07, FR-302 sampai FR-304).
/// Dibuat tanpa overlay autocomplete dan tanpa Row lebar agar stabil pada
/// layar kecil; saran katalog ditampilkan sebagai daftar tombol biasa.
class MedicationFormPage extends StatefulWidget {
  const MedicationFormPage({this.medication, super.key});

  final Medication? medication;

  @override
  State<MedicationFormPage> createState() => _MedicationFormPageState();
}

class _MedicationFormPageState extends State<MedicationFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _dosage;
  late final TextEditingController _notes;

  List<MedicineCatalogItem> _catalog = <MedicineCatalogItem>[];
  MedicineCatalogItem? _selectedCatalog;
  List<TimeOfDay> _times = <TimeOfDay>[const TimeOfDay(hour: 8, minute: 0)];
  String _preset = '1x';
  DateTime _startDate = AppTime.now();
  DateTime? _endDate;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.medication != null;

  @override
  void initState() {
    super.initState();
    final medication = widget.medication;
    _name = TextEditingController(text: medication?.name ?? '');
    _dosage = TextEditingController(text: medication?.dosage ?? '');
    _notes = TextEditingController(text: medication?.notes ?? '');

    if (medication != null) {
      _startDate = medication.startDate;
      _endDate = medication.endDate;
      if (medication.times.isNotEmpty) {
        _times = medication.times.map(_parseTime).toList();
        _preset = 'manual';
      }
    }
    _loadCatalog();
  }

  TimeOfDay _parseTime(MedicationTime value) {
    final parts = value.timeOfDay.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 8,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  Future<void> _loadCatalog() async {
    try {
      final catalog = await Services.medications.fetchCatalog();
      if (!mounted) return;
      setState(() => _catalog = catalog);
    } on Object {
      // Form tetap dapat dipakai dengan nama obat bebas bila katalog gagal.
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _timeText(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  void _setPreset(String value) {
    final times = switch (value) {
      '1x' => <TimeOfDay>[const TimeOfDay(hour: 8, minute: 0)],
      '2x' => <TimeOfDay>[
        const TimeOfDay(hour: 8, minute: 0),
        const TimeOfDay(hour: 20, minute: 0),
      ],
      '3x' => <TimeOfDay>[
        const TimeOfDay(hour: 8, minute: 0),
        const TimeOfDay(hour: 14, minute: 0),
        const TimeOfDay(hour: 20, minute: 0),
      ],
      _ => _times,
    };
    setState(() {
      _preset = value;
      _times = List<TimeOfDay>.from(times);
    });
  }

  Future<void> _changeTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
    );
    if (!mounted || picked == null) return;
    setState(() {
      _times[index] = picked;
      _preset = 'manual';
    });
  }

  void _addTime() {
    if (_times.length >= 4) return;
    setState(() {
      _times.add(const TimeOfDay(hour: 12, minute: 0));
      _preset = 'manual';
    });
  }

  void _removeTime(int index) {
    if (_times.length == 1) return;
    setState(() {
      _times.removeAt(index);
      _preset = 'manual';
    });
  }

  Future<void> _changeEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 730)),
    );
    if (mounted && picked != null) setState(() => _endDate = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final timeStrings = _times.map(_timeText).toList();
    if (timeStrings.toSet().length != timeStrings.length) {
      setState(() => _error = 'Pilih 1 sampai 4 jam yang berbeda');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_editing) {
        await Services.medications.update(
          id: widget.medication!.id,
          name: _name.text,
          dosage: _dosage.text,
          endDate: _endDate,
          notes: _notes.text.isEmpty ? null : _notes.text,
          times: timeStrings,
        );
      } else {
        await Services.medications.create(
          name: _name.text,
          dosage: _dosage.text,
          startDate: _startDate,
          endDate: _endDate,
          notes: _notes.text.isEmpty ? null : _notes.text,
          times: timeStrings,
        );
      }
      await Services.notifications.reschedule();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on Object {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Tidak ada koneksi. Coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _name.text.trim().toLowerCase();
    final suggestions = query.length < 2
        ? <MedicineCatalogItem>[]
        : _catalog
              .where((item) => item.name.toLowerCase().contains(query))
              .take(4)
              .toList();

    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Ubah obat' : 'Tambah obat')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: <Widget>[
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Nama obat',
                  hintText: 'Contoh: Amlodipine',
                ),
                validator: Validators.medicationName,
                onChanged: (_) => setState(() {}),
              ),
              if (suggestions.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                const Text(
                  'Saran katalog',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                ...suggestions.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _name.text = item.name;
                          _selectedCatalog = item;
                          if (item.commonStrengths.isNotEmpty) {
                            _dosage.text = item.commonStrengths.first;
                          }
                        });
                      },
                      icon: const Icon(Icons.medication_outlined),
                      label: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(item.name),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _dosage,
                decoration: const InputDecoration(
                  labelText: 'Dosis',
                  hintText: 'Contoh: 5 mg atau 1 tablet',
                ),
                validator: Validators.dosage,
              ),
              if (_selectedCatalog?.commonStrengths.isNotEmpty ??
                  false) ...<Widget>[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _selectedCatalog!.commonStrengths
                      .map(
                        (strength) => ActionChip(
                          label: Text(strength),
                          onPressed: () =>
                              setState(() => _dosage.text = strength),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey<String>(_preset),
                initialValue: _preset,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Frekuensi'),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(
                    value: '1x',
                    child: Text('1x sehari (08:00)'),
                  ),
                  DropdownMenuItem(
                    value: '2x',
                    child: Text('2x sehari (08:00, 20:00)'),
                  ),
                  DropdownMenuItem(
                    value: '3x',
                    child: Text('3x sehari (08:00, 14:00, 20:00)'),
                  ),
                  DropdownMenuItem(value: 'manual', child: Text('Atur manual')),
                ],
                onChanged: (value) {
                  if (value != null) _setPreset(value);
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Jam minum',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              ..._times.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: <Widget>[
                      CircleAvatar(child: Text('${entry.key + 1}')),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _timeText(entry.value),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(92, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () => _changeTime(entry.key),
                        child: const Text('Ubah jam'),
                      ),
                      if (_times.length > 1)
                        IconButton(
                          onPressed: () => _removeTime(entry.key),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                    ],
                  ),
                ),
              ),
              if (_times.length < 4)
                TextButton.icon(
                  onPressed: _addTime,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah jam'),
                ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: const Text('Tanggal selesai'),
                subtitle: Text(
                  _endDate == null ? 'Tidak ditentukan' : Fmt.date(_endDate!),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _changeEndDate,
              ),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                ),
                validator: Validators.notes,
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              LoadingButton(
                label: _editing ? 'Simpan perubahan' : 'Simpan obat',
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
