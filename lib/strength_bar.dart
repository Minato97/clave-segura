import 'package:flutter/material.dart';

import 'password_logic.dart';

Color strengthColor(Strength s) => switch (s) {
      Strength.veryWeak => Colors.red.shade700,
      Strength.weak => Colors.deepOrange,
      Strength.fair => Colors.amber.shade800,
      Strength.strong => Colors.lightGreen.shade700,
      Strength.veryStrong => Colors.green.shade700,
    };

class StrengthBar extends StatelessWidget {
  const StrengthBar({super.key, required this.bits});

  final double bits;

  @override
  Widget build(BuildContext context) {
    final s = strengthFromBits(bits);
    final color = strengthColor(s);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (bits / 100).clamp(0.04, 1.0),
            minHeight: 10,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${s.label} · ${bits.round()} bits · se tardaría ${crackTime(bits)}',
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
