import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jim_bro/widgets/weight_chart.dart' show WeightEntry;
import 'package:jim_bro/local_storage/shared_prefs.dart';

class WeightEditPage extends StatefulWidget {
  const WeightEditPage({super.key});

  @override
  State<WeightEditPage> createState() => _WeightEditPageState();
}

class _WeightEditPageState extends State<WeightEditPage> {
  List<WeightEntry> _entries = [];
  bool _loading = true;
  bool _useLbs = false;

  // range selection (indices into _entries)
  int _viewStart = 0;
  int _viewEnd = 0;

  // selected entry for dropdown editing (-1 = none)
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // helper to serialize an entry for storage
  String _serializeEntry(WeightEntry e) => '${e.date.toIso8601String()},${e.weight}';

  // helper to parse stored string into WeightEntry (returns null on failure)
  WeightEntry? _parseStored(String s) {
    final parts = s.split(',');
    if (parts.length < 2) return null;
    try {
      final d = DateTime.parse(parts[0]);
      final w = double.parse(parts[1]);
      return WeightEntry(d, w);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();

    // load unit pref
    _useLbs = await SharedPrefsService.getUseLbs();

    final raw = prefs.getStringList('datedWeights') ?? [];
    final list = <WeightEntry>[];
    for (final s in raw) {
      final e = _parseStored(s);
      if (e != null) list.add(e);
    }

    // ensure entries are ordered oldest -> newest
    list.sort((a, b) => a.date.compareTo(b.date));

    // if stored order/content differs from sorted order, rewrite prefs to keep canonical order
    final orderedStrings = list.map(_serializeEntry).toList();
    final rawJoined = raw.join('|');
    final orderedJoined = orderedStrings.join('|');
    if (rawJoined != orderedJoined) {
      await prefs.setStringList('datedWeights', orderedStrings);
    }

    setState(() {
      _entries = list;
      _viewStart = 0;
      _viewEnd = (_entries.isEmpty ? 0 : _entries.length - 1);
      _selectedIndex = (_entries.isEmpty ? -1 : (_entries.length - 1));
      _loading = false;
    });
  }

  Future<void> _upsertEntry(WeightEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'datedWeights';
    final list = prefs.getStringList(key) ?? [];

    final newLine = _serializeEntry(entry);

    final idx = list.indexWhere((s) {
      final parts = s.split(',');
      if (parts.isEmpty) return false;
      try {
        final d = DateTime.parse(parts[0]);
        return d.year == entry.date.year && d.month == entry.date.month && d.day == entry.date.day;
      } catch (_) {
        return false;
      }
    });

    if (idx != -1) {
      list[idx] = newLine;
    } else {
      list.add(newLine);
    }

    // normalize: parse, sort, and save canonical ordered list
    final parsed = <WeightEntry>[];
    for (final s in list) {
      final e = _parseStored(s);
      if (e != null) parsed.add(e);
    }
    parsed.sort((a, b) => a.date.compareTo(b.date));
    final orderedStrings = parsed.map(_serializeEntry).toList();
    await prefs.setStringList(key, orderedStrings);

    await _loadAll();
  }

  Future<void> _deleteEntry(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'datedWeights';
    final list = prefs.getStringList(key) ?? [];

    list.removeWhere((s) {
      final parts = s.split(',');
      if (parts.isEmpty) return false;
      try {
        final d = DateTime.parse(parts[0]);
        return d.year == date.year && d.month == date.month && d.day == date.day;
      } catch (_) {
        return false;
      }
    });

    // normalize remaining entries before saving
    final remaining = <WeightEntry>[];
    for (final s in list) {
      final e = _parseStored(s);
      if (e != null) remaining.add(e);
    }
    remaining.sort((a, b) => a.date.compareTo(b.date));
    final orderedStrings = remaining.map(_serializeEntry).toList();
    await prefs.setStringList(key, orderedStrings);

    await _loadAll();
  }


  String _formatWeightDisplay(double kg) {
    return _useLbs
        ? '${SharedPrefsService.kgToLbs(kg).toStringAsFixed(1)} lb'
        : '${kg.toStringAsFixed(1)} kg';
  }

  Future<void> _showEditDialog({required int index}) async {
    if (index < 0 || index >= _entries.length) return;
    final entry = _entries[index];
    final displayVal = _useLbs ? SharedPrefsService.kgToLbs(entry.weight) : entry.weight;
    final controller = TextEditingController(text: displayVal.toStringAsFixed(1));

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit weight — ${entry.date.month}/${entry.date.day}/${entry.date.year}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: 'Weight (${_useLbs ? 'lb' : 'kg'})'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final parsed = double.tryParse(controller.text);
              if (parsed != null) {
                final kg = _useLbs ? SharedPrefsService.lbsToKg(parsed) : parsed;
                await _upsertEntry(WeightEntry(entry.date, kg));
              }
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Save'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final confirm = await showDialog<bool>(
                context: context,
                builder: (c2) => AlertDialog(
                  title: const Text('Delete entry?'),
                  content: const Text('Remove this date entry permanently?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(c2).pop(false), child: const Text('No')),
                    ElevatedButton(onPressed: () => Navigator.of(c2).pop(true), child: const Text('Delete')),
                  ],
                ),
              );
              if (confirm == true) {
                await _deleteEntry(entry.date);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog() async {
    DateTime chosen = DateTime.now();
    final weightController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setSt) {
        return AlertDialog(
          title: const Text('Add weight entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('${chosen.month}/${chosen.day}/${chosen.year}'),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx2,
                      initialDate: chosen,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setSt(() => chosen = d);
                  },
                ),
              ),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Weight (${_useLbs ? 'lb' : 'kg'})'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx2).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final parsed = double.tryParse(weightController.text);
                if (parsed != null) {
                  final kg = _useLbs ? SharedPrefsService.lbsToKg(parsed) : parsed;
                  await _upsertEntry(WeightEntry(chosen, kg));
                }
                if (ctx2.mounted) {
                  Navigator.of(ctx2).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // clamp view indices to valid range
    if (_entries.isNotEmpty) {
      _viewStart = _viewStart.clamp(0, _entries.length - 1);
      _viewEnd = _viewEnd.clamp(0, _entries.length - 1);
      if (_viewEnd < _viewStart) _viewEnd = _viewStart;
    } else {
      _viewStart = 0;
      _viewEnd = 0;
      _selectedIndex = -1;
    }

    // Build visible slice according to the RangeSlider selection.
    final visibleEntries = (_entries.isEmpty)
        ? <WeightEntry>[]
        : _entries.sublist(_viewStart, _viewEnd + 1); // inclusive

    // Spots for the chart must be contiguous for the visible range to avoid
    // drawing lines outside the viewport. We remap x -> 0..n-1 for visible entries.
    final visibleSpots = List<FlSpot>.generate(visibleEntries.length, (i) {
      final display = _useLbs
          ? SharedPrefsService.kgToLbs(visibleEntries[i].weight)
          : visibleEntries[i].weight;
      return FlSpot(i.toDouble(), display);
    });

    // Compute Y bounds from visible data (fall back to small defaults)
    final yValues = visibleSpots.map((s) => s.y).toList();
    final minY = yValues.isNotEmpty ? yValues.reduce((a, b) => a < b ? a : b) - 1.0 : 0.0;
    final maxY = yValues.isNotEmpty ? yValues.reduce((a, b) => a > b ? a : b) + 1.0 : 10.0;
    final xCount = visibleSpots.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Weights'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Text('No weight entries yet. Tap + to add one.',
                      style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700])),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 32, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Chart
                          SizedBox(
                            height: 300,
                            child: LineChart(
                              LineChartData(
                                // use remapped visibleSpots coordinates so lines only connect visible points
                                minX: 0.0,
                                maxX: (xCount > 0) ? (xCount - 1).toDouble() : 0.0,
                                minY: minY,
                                maxY: maxY,
                                gridData: FlGridData(show: true),
                                titlesData: FlTitlesData(
                                  // show LEFT axis numbers (using the same styling/interval previously on the right)
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: (() {
                                        final range = (maxY - minY).abs();
                                        return range > 0 ? range / 4.0 : 1.0;
                                      })(),
                                      getTitlesWidget: (value, meta) => Text(
                                        value.toStringAsFixed(1),
                                        style: TextStyle(
                                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                                          fontSize: 10,
                                        ),
                                      ),
                                      reservedSize: 44,
                                    ),
                                  ),
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  // remove right axis numbers
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 1,
                                      getTitlesWidget: (value, meta) {
                                        final rounded = value.round();
                                        if (rounded < 0 || rounded >= visibleEntries.length) return const SizedBox.shrink();
                                        final originalIdx = _viewStart + rounded;
                                        final d = _entries[originalIdx].date;
                                        return Text(
                                          '${d.month}/${d.day}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    // use only visible spots remapped to 0..n-1 so the line does not
                                    // connect across hidden data
                                    spots: visibleSpots,
                                    isCurved: true,
                                    barWidth: 2,
                                    color: Colors.indigoAccent[700],
                                    dotData: FlDotData(show: true),
                                  ),
                                ],
                                lineTouchData: LineTouchData(
                                  // only trigger edit on explicit tap (click), not on hover/pan
                                  touchCallback: (event, response) {
                                    final spot = response?.lineBarSpots?.first;
                                    // require a tap-up event to open edit dialog
                                    if (spot != null && event is FlTapUpEvent) {
                                      // map remapped x back to original index
                                      final remappedIdx = spot.x.toInt();
                                      final originalIdx = _viewStart + remappedIdx;
                                      if (originalIdx >= 0 && originalIdx < _entries.length) _showEditDialog(index: originalIdx);
                                    }
                                  },
                                  handleBuiltInTouches: true,
                                  touchTooltipData: LineTouchTooltipData(
                                    getTooltipItems: (touched) => touched.map((t) {
                                      // t.x is remapped index; convert to original
                                      final remapped = t.x.round();
                                      final original = _viewStart + remapped;
                                      if (original < 0 || original >= _entries.length) return null;
                                      final e = _entries[original];
                                      return LineTooltipItem(
                                        '${e.date.month}/${e.date.day}\n${_formatWeightDisplay(e.weight)}',
                                        const TextStyle(color: Colors.white),
                                      );
                                    }).whereType<LineTooltipItem>().toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Range selector
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              children: [
                                const Text('Range:'),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: RangeSlider(
                                    values: RangeValues(_viewStart.toDouble(), _viewEnd.toDouble()),
                                    min: 0,
                                    max: (_entries.length - 1).toDouble(),
                                    // divisions null when there's only one point -> prevents errors
                                    divisions: (_entries.length - 1) > 0 ? (_entries.length - 1) : null,
                                    labels: RangeLabels(
                                      '${_entries[_viewStart].date.month}/${_entries[_viewStart].date.day}',
                                      '${_entries[_viewEnd].date.month}/${_entries[_viewEnd].date.day}',
                                    ),
                                    onChanged: (r) {
                                      setState(() {
                                        _viewStart = r.start.round().clamp(0, _entries.length - 1);
                                        _viewEnd = r.end.round().clamp(0, _entries.length - 1);
                                        if (_viewEnd < _viewStart) _viewEnd = _viewStart;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Dropdown to pick a single date to edit (simpler than listing all)
                          if (_entries.isNotEmpty) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButton<int>(
                                    isExpanded: true,
                                    value: (_selectedIndex >= 0 && _selectedIndex < _entries.length) ? _selectedIndex : null,
                                    hint: const Text('Select date to edit'),
                                    items: List.generate(_entries.length, (i) {
                                      final e = _entries[i];
                                      final label = '${e.date.month}/${e.date.day}/${e.date.year}';
                                      return DropdownMenuItem<int>(
                                        value: i,
                                        child: Text('$label — ${_formatWeightDisplay(e.weight)}'),
                                      );
                                    }),
                                    onChanged: (v) {
                                      if (v == null) return;
                                      setState(() => _selectedIndex = v);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Edit selected',
                                  icon: const Icon(Icons.edit),
                                  onPressed: (_selectedIndex >= 0 && _selectedIndex < _entries.length)
                                      ? () => _showEditDialog(index: _selectedIndex)
                                      : null,
                                ),
                                IconButton(
                                  tooltip: 'Delete selected',
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: (_selectedIndex >= 0 && _selectedIndex < _entries.length)
                                      ? () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (c) => AlertDialog(
                                              title: const Text('Delete entry?'),
                                              content: const Text('Remove this date entry permanently?'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('No')),
                                                ElevatedButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Delete')),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            // store current index, delete, then update selection after reload
                                            final sel = _selectedIndex;
                                            await _deleteEntry(_entries[sel].date);
                                            // after _deleteEntry -> _loadAll() ran, so _entries updated
                                            setState(() {
                                              _selectedIndex = (_entries.isEmpty ? -1 : sel.clamp(0, _entries.length - 1).toInt());
                                              _viewStart = _viewStart.clamp(0, _entries.isEmpty ? 0 : _entries.length - 1);
                                              _viewEnd = _viewEnd.clamp(0, _entries.isEmpty ? 0 : _entries.length - 1);
                                            });
                                          }
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          ] else
                            const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}