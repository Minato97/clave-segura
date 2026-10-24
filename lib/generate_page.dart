import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ads.dart';
import 'password_logic.dart';
import 'strength_bar.dart';

class GeneratePage extends StatefulWidget {
  const GeneratePage({super.key});

  @override
  State<GeneratePage> createState() => _GeneratePageState();
}

class _GeneratePageState extends State<GeneratePage> {
  final _opts = PasswordOptions();
  bool _passphrase = false;
  int _words = 6;
  late String _value = generatePassword(_opts);

  void _regenerate() {
    setState(() {
      _value = _passphrase
          ? generatePassphrase(words: _words)
          : generatePassword(_opts);
    });
    AdService.instance.maybeShowInterstitial(every: 6);
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _value));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copiada al portapapeles')),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) =>
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(label),
        value: value,
        onChanged: (v) {
          // Siempre debe quedar al menos un tipo de caracter activo.
          onChanged(v);
          if (!_opts.isValid) onChanged(true);
          setState(() {});
          _regenerate();
        },
      );

  @override
  Widget build(BuildContext context) {
    final bits = _passphrase
        ? passphraseEntropy(_words)
        : passwordEntropy(_opts);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Contraseña')),
            ButtonSegment(value: true, label: Text('Frase')),
          ],
          selected: {_passphrase},
          onSelectionChanged: (s) {
            _passphrase = s.first;
            _regenerate();
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF0891B2)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lock, color: Colors.white70, size: 18),
                  SizedBox(width: 6),
                  Text('Tu nueva clave',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 10),
              SelectableText(
                _value,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        StrengthBar(bits: bits),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _regenerate,
                icon: const Icon(Icons.refresh),
                label: const Text('Generar otra'),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _copy,
              icon: const Icon(Icons.copy),
              label: const Text('Copiar'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_passphrase) ...[
          Text('Palabras: $_words'),
          Slider(
            value: _words.toDouble(),
            min: 4,
            max: 10,
            divisions: 6,
            label: '$_words',
            onChanged: (v) => setState(() => _words = v.round()),
            onChangeEnd: (_) => _regenerate(),
          ),
        ] else ...[
          Text('Longitud: ${_opts.length}'),
          Slider(
            value: _opts.length.toDouble(),
            min: 8,
            max: 64,
            divisions: 56,
            label: '${_opts.length}',
            onChanged: (v) => setState(() => _opts.length = v.round()),
            onChangeEnd: (_) => _regenerate(),
          ),
          _toggle('Minúsculas (a-z)', _opts.lower, (v) => _opts.lower = v),
          _toggle('Mayúsculas (A-Z)', _opts.upper, (v) => _opts.upper = v),
          _toggle('Números (0-9)', _opts.digits, (v) => _opts.digits = v),
          _toggle('Símbolos (!@#\$%)', _opts.symbols, (v) => _opts.symbols = v),
          _toggle('Evitar caracteres confusos (I, l, 1, O, 0)',
              _opts.avoidAmbiguous, (v) => _opts.avoidAmbiguous = v),
        ],
      ],
    );
  }
}
