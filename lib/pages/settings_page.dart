import 'package:flutter/material.dart';
import 'package:jim_bro/local_storage/shared_prefs.dart';
import 'package:jim_bro/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {

  const SettingsPage({
    super.key,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _processing = false;

  // unit preference local state
  bool _useLbs = false;

  @override
  void initState() {
    super.initState();
    _loadUnitPref();
  }

  Future<void> _loadUnitPref() async {
    final useLbs = await SharedPrefsService.getUseLbs();
    if (mounted) setState(() => _useLbs = useLbs);
  }

  Future<void> _setUseLbs(bool value) async {
    await SharedPrefsService.setUseLbs(value);

    if (!mounted) return;

    setState(() => _useLbs = value);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Units set to ${value ? 'lbs' : 'kg'}'),
      ),
    );
  }

  Future<void> _confirmAndClearPrefs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear app data'),
        content: const Text('This will remove all stored preferences. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Clear')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _processing = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App data cleared.')),
      );
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear data: $err')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _openWeightEdit() {
    Navigator.of(context).pushNamed('/weight-edit');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            secondary:  Icon(Provider.of<ThemeProvider>(context).isDarkMode()
                ? Icons.dark_mode
                : Icons.light_mode),
            title: const Text('Dark theme'),
            value: Provider.of<ThemeProvider>(context).isDarkMode(),
            onChanged: (value) {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme(value);
            },
          ),

          const Divider(),

          // Unit preference UI
          SwitchListTile(
            value: _useLbs,
            onChanged: (v) => _setUseLbs(v),
            title: const Text('Use pounds (lbs)'),
            subtitle: const Text('Toggle to display weights in lbs instead of kg'),
            secondary: const Icon(Icons.swap_vert),
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.flag),
            title: const Text('Edit weight details'),
            onTap: _openWeightEdit,
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text('Clear app data'),
            onTap: _processing ? null : _confirmAndClearPrefs,
          ),

          if (_processing) ...[
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}