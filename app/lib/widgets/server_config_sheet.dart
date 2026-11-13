import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';

Future<void> showServerConfigSheet(BuildContext context, {VoidCallback? onSaved}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Solis.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _ServerConfigModal(onSaved: onSaved),
  );
}

class _ServerConfigModal extends StatefulWidget {
  const _ServerConfigModal({this.onSaved});
  final VoidCallback? onSaved;

  @override
  State<_ServerConfigModal> createState() => _ServerConfigModalState();
}

class _ServerConfigModalState extends State<_ServerConfigModal> {
  late final TextEditingController _urlCtrl;
  bool _testing = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: AppConfig.apiUrl);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final candidate = _urlCtrl.text.trim();
    if (candidate.isEmpty) return;

    final base = candidate.endsWith('/') ? candidate.substring(0, candidate.length - 1) : candidate;
    setState(() {
      _testing = true;
      _testResult = null;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final res = await http.get(
        Uri.parse('$base/health'),
        headers: {'Bypass-Tunnel-Reminder': 'true'},
      ).timeout(const Duration(seconds: 4));
      stopwatch.stop();

      if (res.statusCode == 200) {
        try {
          final data = jsonDecode(res.body);
          if (data is Map && data['ok'] == true) {
            setState(() {
              _testSuccess = true;
              _testResult = 'Online! Latency: ${stopwatch.elapsedMilliseconds}ms';
            });
            return;
          }
        } catch (_) {}
        setState(() {
          _testSuccess = true;
          _testResult = 'Server reachable (${res.statusCode}) - ${stopwatch.elapsedMilliseconds}ms';
        });
      } else {
        setState(() {
          _testSuccess = false;
          _testResult = 'Server returned status ${res.statusCode}';
        });
      }
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _testSuccess = false;
        _testResult = 'Unreachable: ${e.toString().split('\n').first}';
      });
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    final candidate = _urlCtrl.text.trim();
    await AppConfig.setCustomUrl(candidate.isEmpty ? null : candidate);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Server connected: ${AppConfig.apiUrl}', style: Solis.sans(14, color: Solis.paper)),
        backgroundColor: Solis.teal,
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Solis.line, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Solis.sun.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(Icons.dns_rounded, color: Solis.sun, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Server Connection', style: Solis.serif(20, weight: FontWeight.w600)),
                  Text('Connect Android phone to Solis backend', style: Solis.sans(13, color: Solis.muted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _urlCtrl,
            decoration: InputDecoration(
              labelText: 'API Endpoint URL',
              hintText: 'https://...',
              filled: true,
              fillColor: Solis.paper,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Solis.line)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => _urlCtrl.clear(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('Quick Presets:', style: Solis.sans(12, color: Solis.muted, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _presetChip('🌐 Cloud Tunnel', AppConfig.publicTunnelUrl),
              _presetChip('📶 Local Wi-Fi', AppConfig.lanWifiUrl),
              _presetChip('📱 Android Emulator', AppConfig.emulatorUrl),
              _presetChip('💻 Localhost', AppConfig.localhostUrl),
            ],
          ),
          if (_testResult != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _testSuccess ? Solis.teal.withValues(alpha: 0.1) : Solis.rust.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _testSuccess ? Solis.teal : Solis.rust, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(_testSuccess ? Icons.check_circle_outline : Icons.error_outline,
                      color: _testSuccess ? Solis.teal : Solis.rust, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _testResult!,
                      style: Solis.sans(13, color: _testSuccess ? Solis.teal : Solis.rust, weight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: _testing
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Solis.ink))
                      : const Icon(Icons.bolt_outlined, size: 18),
                  label: Text(_testing ? 'Testing...' : 'Test Ping', style: Solis.sans(14, weight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Solis.line),
                  ),
                  onPressed: _testing ? null : _testConnection,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 18, color: Solis.paper),
                  label: Text('Save & Apply', style: Solis.sans(14, color: Solis.paper, weight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Solis.ink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetChip(String label, String url) {
    final isSelected = _urlCtrl.text.trim() == url;
    return ActionChip(
      label: Text(label, style: Solis.sans(12, color: isSelected ? Solis.paper : Solis.ink)),
      backgroundColor: isSelected ? Solis.ink : Solis.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? Solis.ink : Solis.line),
      ),
      onPressed: () {
        setState(() {
          _urlCtrl.text = url;
          _testResult = null;
        });
        _testConnection();
      },
    );
  }
}
