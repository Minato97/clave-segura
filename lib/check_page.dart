import 'package:flutter/material.dart';

import 'ads.dart';
import 'password_logic.dart';
import 'strength_bar.dart';

class CheckPage extends StatefulWidget {
  const CheckPage({super.key});

  @override
  State<CheckPage> createState() => _CheckPageState();
}

class _CheckPageState extends State<CheckPage> {
  final _controller = TextEditingController();
  bool _hidden = true;
  Analysis _analysis = Analysis(0, const []);
  int _checks = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    setState(() => _analysis = analyzePassword(v));
    if (v.length >= 8 && ++_checks % 12 == 0) {
      AdService.instance.maybeShowInterstitial(every: 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _controller,
          obscureText: _hidden,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: _onChanged,
          decoration: InputDecoration(
            labelText: 'Escribe una contraseña para evaluarla',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _hidden = !_hidden),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'El análisis se hace en tu dispositivo; la contraseña no se envía ni se guarda.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        if (_controller.text.isNotEmpty) ...[
          StrengthBar(bits: _analysis.bits),
          const SizedBox(height: 16),
          for (final t in _analysis.tips)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lightbulb_outline),
              title: Text(t),
            ),
          if (_analysis.tips.isEmpty)
            const ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.check_circle_outline),
              title: Text('Se ve bien. Usa una contraseña distinta en cada sitio.'),
            ),
        ],
      ],
    );
  }
}
