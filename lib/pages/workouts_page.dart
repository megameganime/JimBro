import 'package:flutter/material.dart';
import 'package:jim_bro/local_storage/shared_prefs.dart';
import 'package:jim_bro/models/workout_models.dart';

class WorkoutsPage extends StatefulWidget {
  const WorkoutsPage({super.key});

  @override
  WorkoutsPageState createState() => WorkoutsPageState();
}

class WorkoutsPageState extends State<WorkoutsPage> {
  DateTime _selectedDate = DateTime.now();
  List<WorkoutInstance> _instances = [];
  List<WorkoutTemplate> _templates = [];
  bool _useLbs = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final useLbs = await SharedPrefsService.getUseLbs();
    final templates = await SharedPrefsService.getWorkoutTemplates();
    final instances = await SharedPrefsService.getWorkoutInstancesForDate(_selectedDate);
    setState(() {
      _useLbs = useLbs;
      _templates = templates;
      _instances = instances;
    });
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) {
      setState(() => _selectedDate = d);
      final instances = await SharedPrefsService.getWorkoutInstancesForDate(d);
      setState(() => _instances = instances);
    }
  }

  Future<void> _toggleUnit() async {
    await SharedPrefsService.setUseLbs(!_useLbs);
    await _loadAll();
  }

  Future<void> _showTemplatesManager() async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          Future<void> editTemplate([WorkoutTemplate? template]) async {
            final nameCtrl = TextEditingController(text: template?.name ?? '');
            final List<TextEditingController> exCtrls =
                (template?.exerciseNames ?? []).map((e) => TextEditingController(text: e)).toList();

            await showDialog(
              context: ctx,
              builder: (ctx2) {
                return StatefulBuilder(builder: (ctx2, setInner) {
                  return AlertDialog(
                    title: Text(template == null ? 'New Template' : 'Edit Template'),
                    content: SingleChildScrollView(
                      child: Column(
                        children: [
                          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Template name')),
                          const SizedBox(height: 8),
                          Column(
                            children: [
                              for (var i = 0; i < exCtrls.length; i++) 
                                (() {
                                  final idx = i;
                                  return Row(
                                    children: [
                                      Expanded(child: TextField(controller: exCtrls[idx], decoration: const InputDecoration(labelText: 'Exercise name'))),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => setInner(() => exCtrls.removeAt(idx)),
                                      ),
                                    ],
                                  );
                                })(),
                              TextButton.icon(
                                onPressed: () => setInner(() => exCtrls.add(TextEditingController())),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Exercise'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx2).pop(), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;
                          final exNames = exCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
                          if (template == null) {
                            final t = WorkoutTemplate.create(name, exNames);
                            await SharedPrefsService.saveWorkoutTemplate(t);
                          } else {
                            final updated = WorkoutTemplate(id: template.id, name: name, exerciseNames: exNames);
                            await SharedPrefsService.saveWorkoutTemplate(updated);
                          }
                          final templates = await SharedPrefsService.getWorkoutTemplates();
                          setDialogState(() => _templates = templates);
                          if (ctx2.mounted) Navigator.of(ctx2).pop();
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  );
                });
              },
            );
          }

          return AlertDialog(
            title: const Text('Manage Templates'),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final t in _templates)
                      Card(
                        child: ListTile(
                          title: Text(t.name),
                          subtitle: Text(t.exerciseNames.join(', ')),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'edit') {
                                await editTemplate(t);
                              } else if (v == 'delete') {
                                await SharedPrefsService.deleteWorkoutTemplate(t.id);
                                final templates = await SharedPrefsService.getWorkoutTemplates();
                                setDialogState(() => _templates = templates);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        ),
                      ),
                    TextButton.icon(
                      onPressed: () => editTemplate(null),
                      icon: const Icon(Icons.add),
                      label: const Text('New Template'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close'))],
          );
        });
      },
    );
    await _loadAll();
  }

  Future<void> _showCreateWorkoutDialog() async {
    final nameCtrl = TextEditingController();
    String? selectedTemplateId;
    List<ExerciseEditorState> exercises = [];

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          void loadTemplate(String id) {
            final t = _templates.firstWhere((tt) => tt.id == id);
            nameCtrl.text = t.name;
            exercises = t.exerciseNames.map((n) => ExerciseEditorState(name: n)).toList();
          }

          return AlertDialog(
            title: const Text('Create Workout'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Workout name')),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedTemplateId,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None / New')),
                      ..._templates.map((t) => DropdownMenuItem(value: t.id, child: Text('Template: ${t.name}'))),
                    ],
                    onChanged: (v) => setDialogState(() {
                      selectedTemplateId = v;
                      exercises = [];
                      if (v != null) loadTemplate(v);
                    }),
                    decoration: const InputDecoration(labelText: 'Load template (optional)'),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      for (var i = 0; i < exercises.length; i++)
                        (() {
                          final idx = i;
                          return exercises[idx].buildEditor(setDialogState, onRemove: () => setDialogState(() => exercises.removeAt(idx)), unitLabel: _useLbs ? 'lb' : 'kg');
                        })(),
                      TextButton.icon(
                        onPressed: () => setDialogState(() => exercises.add(ExerciseEditorState())),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Exercise'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final workoutName = nameCtrl.text.trim();
                  if (workoutName.isEmpty) return;
                  // build instance
                  final exList = exercises.map((ee) {
                    final exName = ee.nameController.text.trim().isEmpty ? 'Exercise' : ee.nameController.text.trim();
                    final ex = Exercise.create(exName);
                    final sets = ee.setEditors.map((se) {
                      final reps = int.tryParse(se.repsController.text) ?? 0;
                      final weight = double.tryParse(se.weightController.text) ?? 0.0;
                      final durationSec = int.tryParse(se.durationController.text);
                      // weight currently is in user's display units; saveWorkoutInstance will
                      // convert lbs->kg if user's preference is lbs.
                      return SetEntry(weightKg: weight, reps: reps, durationSeconds: durationSec);
                    }).toList();
                    return Exercise(id: ex.id, name: ex.name, sets: sets);
                  }).toList();

                  final instance = WorkoutInstance.create(templateId: selectedTemplateId, date: _selectedDate, exercises: exList);

                  await SharedPrefsService.saveWorkoutInstance(instance);

                  final saveAsTemplate = await showDialog<bool>(
                        context: context,
                        builder: (ctx2) => AlertDialog(
                          title: const Text('Save as template?'),
                          content: const Text('Save workout and exercises as a template for reuse?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx2).pop(false), child: const Text('No')),
                            TextButton(onPressed: () => Navigator.of(ctx2).pop(true), child: const Text('Yes')),
                          ],
                        ),
                      ) ??
                      false;

                  if (saveAsTemplate) {
                    final template = WorkoutTemplate.create(
                      workoutName,
                      exList.map((e) => e.name).toList(),
                    );
                    await SharedPrefsService.saveWorkoutTemplate(template);
                  }

                  await _loadAll();
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: const Text('Save Workout'),
              ),
            ],
          );
        });
      },
    );
  }

  // ----- new: edit an existing workout instance -----
  Future<void> _showEditWorkoutDialog(WorkoutInstance inst) async {
    // prepare editors prefilled with instance data (weights are in display units already from getWorkoutInstancesForDate)
    String? selectedTemplateId = inst.templateId;
    final nameCtrl = TextEditingController(text: _templateNameForId(inst.templateId));
    // preserve original exercise ids by passing them into the editor
    final exercises = inst.exercises.map((e) {
      final ee = ExerciseEditorState(id: e.id, name: e.name, existingSets: e.sets);
      return ee;
    }).toList();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Workout'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Workout name (optional)')),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedTemplateId,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None / New')),
                      ..._templates.map((t) => DropdownMenuItem(value: t.id, child: Text('Template: ${t.name}'))),
                    ],
                    onChanged: (v) => setDialogState(() {
                      selectedTemplateId = v;
                      if (v != null) {
                        final t = _templates.firstWhere((tt) => tt.id == v);
                        // replace exercises with template exercise names (no sets)
                        final replaced = t.exerciseNames.map((n) => ExerciseEditorState(name: n)).toList();
                        exercises.clear();
                        exercises.addAll(replaced);
                        nameCtrl.text = t.name;
                      }
                    }),
                    decoration: const InputDecoration(labelText: 'Load template (optional)'),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      for (var i = 0; i < exercises.length; i++)
                        (() {
                          final idx = i;
                          return exercises[idx].buildEditor(setDialogState, onRemove: () => setDialogState(() => exercises.removeAt(idx)), unitLabel: _useLbs ? 'lb' : 'kg');
                        })(),
                      TextButton.icon(
                        onPressed: () => setDialogState(() => exercises.add(ExerciseEditorState())),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Exercise'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  // build updated instance keeping same id and date
                  final exList = exercises.map((ee) {
                    final exName = ee.nameController.text.trim().isEmpty ? 'Exercise' : ee.nameController.text.trim();
                    final sets = ee.setEditors.map((se) {
                      final reps = int.tryParse(se.repsController.text) ?? 0;
                      final weight = double.tryParse(se.weightController.text) ?? 0.0;
                      final durationSec = int.tryParse(se.durationController.text);
                      return SetEntry(weightKg: weight, reps: reps, durationSeconds: durationSec);
                    }).toList();
                    final idToUse = ee.id ?? DateTime.now().millisecondsSinceEpoch.toString();
                    return Exercise(id: idToUse, name: exName, sets: sets);
                  }).toList();

                  final updated = WorkoutInstance(
                    id: inst.id,
                    templateId: selectedTemplateId,
                    date: inst.date,
                    exercises: exList,
                  );

                  await SharedPrefsService.saveWorkoutInstance(updated);
                  await _loadAll();
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        });
      },
    );
  }

  String _templateNameForId(String? id) {
    if (id == null) return '';
    final t = _templates.where((tt) => tt.id == id);
    if (t.isEmpty) return '';
    return t.first.name;
  }

  Widget _buildInstanceTile(WorkoutInstance inst) {
    return Card(
      child: ExpansionTile(
        title: Text(inst.templateId != null ? 'From template • ${inst.date.toLocal().toIso8601String().substring(0, 10)}' : inst.date.toLocal().toIso8601String().substring(0, 10)),
        subtitle: Text('${inst.exercises.length} exercise(s)'),
        children: [
          for (var i = 0; i < inst.exercises.length; i++)
            (() {
              final idx = i;
              final ex = inst.exercises[idx];
              return ListTile(
                title: Text(ex.name),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditExerciseDialog(inst, ex),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final s in ex.sets)
                      Text('- ${s.reps} reps • ${s.weightKg.toStringAsFixed(1)} ${_useLbs ? 'lb' : 'kg'}${s.durationSeconds != null ? ' • ${s.durationSeconds}s' : ''}'),
                  ],
                ),
              );
            })(),
          OverflowBar(
            children: [
              TextButton(
                onPressed: () async {
                  await SharedPrefsService.deleteWorkoutInstance(inst.id, inst.date);
                  await _loadAll();
                },
                child: const Text('Delete'),
              ),
              TextButton(
                onPressed: () => _showEditWorkoutDialog(inst),
                child: const Text('Edit'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showEditExerciseDialog(WorkoutInstance inst, Exercise ex) async {
    // Create editor prefilled with this exercise data
    final editor = ExerciseEditorState(id: ex.id, name: ex.name, existingSets: ex.sets);

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          Future<void> deleteExercise() async {
            final updatedExercises = inst.exercises.where((e) => e.id != ex.id).toList();
            final updatedInstance = WorkoutInstance(id: inst.id, templateId: inst.templateId, date: inst.date, exercises: updatedExercises);
            await SharedPrefsService.saveWorkoutInstance(updatedInstance);
            await _loadAll();
            if (ctx.mounted) Navigator.of(ctx).pop();
          }

          return AlertDialog(
            title: const Text('Edit Exercise'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ExerciseEditorState exposes buildEditor for full UI
                  editor.buildEditor(setDialogState, onRemove: () { deleteExercise(); }, unitLabel: _useLbs ? 'lb' : 'kg'),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              TextButton(
                onPressed: () async {
                  // delete button in actions (red)
                  await deleteExercise();
                },
                child: Text('Delete', style: TextStyle(color: Colors.red[700])),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Build updated Exercise keeping same id
                  final updatedSets = editor.setEditors.map((se) {
                    final reps = int.tryParse(se.repsController.text) ?? 0;
                    final weight = double.tryParse(se.weightController.text) ?? 0.0;
                    final durationSec = int.tryParse(se.durationController.text);
                    return SetEntry(weightKg: weight, reps: reps, durationSeconds: durationSec);
                  }).toList();

                  final updatedExercise = Exercise(id: ex.id, name: editor.nameController.text.trim().isEmpty ? ex.name : editor.nameController.text.trim(), sets: updatedSets);

                  // Replace exercise in instance by index (safer than id-match in case of duplicates)
                  final idx = inst.exercises.indexWhere((e) => e.id == ex.id);
                  final updatedExercises = List<Exercise>.from(inst.exercises);
                  if (idx != -1) {
                    updatedExercises[idx] = updatedExercise;
                  } else {
                    // fallback - replace first occurrence with same name, otherwise append
                    final byName = updatedExercises.indexWhere((e) => e.name == ex.name);
                    if (byName != -1) {
                      updatedExercises[byName] = updatedExercise;
                    } else {
                      updatedExercises.add(updatedExercise);
                    }
                  }

                  final updatedInstance = WorkoutInstance(id: inst.id, templateId: inst.templateId, date: inst.date, exercises: updatedExercises);

                  await SharedPrefsService.saveWorkoutInstance(updatedInstance);
                  await _loadAll();
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _selectedDate.toLocal().toIso8601String().substring(0, 10);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today), onPressed: _pickDate),
          IconButton(icon: const Icon(Icons.fitness_center), onPressed: _showCreateWorkoutDialog),
          IconButton(icon: const Icon(Icons.table_rows), onPressed: _showTemplatesManager),
          IconButton(
            icon: Icon(_useLbs ? Icons.swap_horiz : Icons.swap_vert),
            tooltip: _useLbs ? 'Units: lbs (tap to switch to kg)' : 'Units: kg (tap to switch to lbs)',
            onPressed: _toggleUnit,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text('Selected date: $dateLabel', style: const TextStyle(fontSize: 16)),
                const Spacer(),
                Text(_useLbs ? 'Units: lbs' : 'Units: kg'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _instances.isEmpty
                  ? Center(child: Text('No workouts for $dateLabel'))
                  : ListView.builder(
                      itemCount: _instances.length,
                      itemBuilder: (ctx, i) => _buildInstanceTile(_instances[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// helper small editors used inside dialog; kept local for simplicity
class ExerciseEditorState {
  final String? id; // preserve original exercise id when editing
  final TextEditingController nameController;
  final List<SetEditorState> setEditors = [];

  ExerciseEditorState({this.id, String? name, List<SetEntry>? existingSets}) : nameController = TextEditingController(text: name ?? '') {
    if (existingSets != null) {
      for (final s in existingSets) {
        // create independent editor state copies so we don't mutate original objects
        setEditors.add(SetEditorState.fromSetEntry(s));
      }
    }
  }

  Widget buildEditor(void Function(void Function()) setState, {required VoidCallback onRemove, String unitLabel = 'kg'}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Exercise name'),
                  ),
                ),
                IconButton(icon: const Icon(Icons.delete), onPressed: onRemove),
              ],
            ),
            Column(
              children: [
                for (var i = 0; i < setEditors.length; i++)
                  (() {
                    final idx = i;
                    return setEditors[idx].buildEditor(setState, onRemove: () => setState(() => setEditors.removeAt(idx)), unitLabel: unitLabel);
                  })(),
                TextButton.icon(
                  onPressed: () => setState(() => setEditors.add(SetEditorState())),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Set'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class SetEditorState {
  final TextEditingController repsController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController durationController = TextEditingController();

  SetEditorState();

  SetEditorState.fromSetEntry(SetEntry s) {
    repsController.text = s.reps.toString();
    // SetEntry.weightKg is holding display units if service converted on load
    weightController.text = s.weightKg.toStringAsFixed(1);
    if (s.durationSeconds != null) durationController.text = s.durationSeconds.toString();
  }

  Widget buildEditor(void Function(void Function()) setState, {required VoidCallback onRemove, String unitLabel = 'kg'}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: TextField(controller: repsController, decoration: const InputDecoration(labelText: 'Reps'), keyboardType: TextInputType.number)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: weightController,
              decoration: InputDecoration(labelText: 'Weight ($unitLabel)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: durationController, decoration: const InputDecoration(labelText: 'Seconds (opt)'), keyboardType: TextInputType.number)),
          IconButton(icon: const Icon(Icons.delete), onPressed: onRemove),
        ],
      ),
    );
  }
}