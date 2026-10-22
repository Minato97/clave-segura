import 'dart:math';

import 'wordlist.dart';

final _rng = Random.secure();

const _lower = 'abcdefghijklmnopqrstuvwxyz';
const _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const _digits = '0123456789';
const _symbols = '!@#\$%^&*()-_=+[]{};:,.?';
const _ambiguous = 'Il1O0o';

class PasswordOptions {
  PasswordOptions({
    this.length = 16,
    this.lower = true,
    this.upper = true,
    this.digits = true,
    this.symbols = true,
    this.avoidAmbiguous = false,
  });

  int length;
  bool lower;
  bool upper;
  bool digits;
  bool symbols;
  bool avoidAmbiguous;

  List<String> get _pools {
    String clean(String s) => avoidAmbiguous
        ? s.split('').where((c) => !_ambiguous.contains(c)).join()
        : s;
    return [
      if (lower) clean(_lower),
      if (upper) clean(_upper),
      if (digits) clean(_digits),
      if (symbols) _symbols,
    ];
  }

  bool get isValid => _pools.isNotEmpty;
}

/// Genera una contraseña con al menos un caracter de cada tipo elegido.
String generatePassword(PasswordOptions o) {
  final pools = o._pools;
  if (pools.isEmpty) return '';
  final all = pools.join();
  final chars = <String>[
    for (final p in pools) p[_rng.nextInt(p.length)],
  ];
  while (chars.length < o.length) {
    chars.add(all[_rng.nextInt(all.length)]);
  }
  chars.shuffle(_rng);
  return chars.take(o.length).join();
}

/// Frase de contraseña: palabras al azar separadas, con opcion de numero.
String generatePassphrase({
  int words = 6,
  String separator = '-',
  bool capitalize = true,
  bool addNumber = true,
}) {
  final parts = <String>[
    for (var i = 0; i < words; i++)
      () {
        final w = wordlist[_rng.nextInt(wordlist.length)];
        return capitalize ? w[0].toUpperCase() + w.substring(1) : w;
      }(),
  ];
  var phrase = parts.join(separator);
  if (addNumber) phrase += separator + _rng.nextInt(100).toString();
  return phrase;
}

/// Bits de entropia de una contraseña generada con las opciones dadas.
double passwordEntropy(PasswordOptions o) {
  final size = o._pools.join().length;
  return size <= 1 ? 0 : o.length * (log(size) / ln2);
}

/// Bits de entropia de una frase de contraseña.
double passphraseEntropy(int words, {bool addNumber = true}) =>
    words * (log(wordlist.length) / ln2) + (addNumber ? log(100) / ln2 : 0);

enum Strength { veryWeak, weak, fair, strong, veryStrong }

extension StrengthText on Strength {
  String get label => switch (this) {
        Strength.veryWeak => 'Muy débil',
        Strength.weak => 'Débil',
        Strength.fair => 'Aceptable',
        Strength.strong => 'Fuerte',
        Strength.veryStrong => 'Muy fuerte',
      };
}

Strength strengthFromBits(double bits) {
  if (bits < 28) return Strength.veryWeak;
  if (bits < 40) return Strength.weak;
  if (bits < 60) return Strength.fair;
  if (bits < 80) return Strength.strong;
  return Strength.veryStrong;
}

const _common = [
  '123456', 'password', 'contrasena', 'qwerty', 'abc123', '111111',
  '123123', 'iloveyou', 'admin', 'letmein', 'welcome', 'monkey', 'dragon',
  'football', 'futbol', 'te amo', 'teamo', 'hola123', 'clave', '000000',
  'qwertyuiop', 'zxcvbnm', 'asdfgh', 'princesa', 'mexico', 'america',
];

class Analysis {
  Analysis(this.bits, this.tips);
  final double bits;
  final List<String> tips;
  Strength get strength => strengthFromBits(bits);
}

/// Estimacion local y conservadora; nada sale del dispositivo.
Analysis analyzePassword(String pwd) {
  if (pwd.isEmpty) return Analysis(0, const []);
  final tips = <String>[];
  var pool = 0;
  if (pwd.contains(RegExp(r'[a-z]'))) pool += 26;
  if (pwd.contains(RegExp(r'[A-Z]'))) pool += 26;
  if (pwd.contains(RegExp(r'[0-9]'))) pool += 10;
  if (pwd.contains(RegExp(r'[^A-Za-z0-9]'))) pool += 28;
  var bits = pwd.length * (log(max(pool, 2)) / ln2);

  final lowered = pwd.toLowerCase();
  if (_common.any((c) => lowered.contains(c))) {
    bits = min(bits, 20);
    tips.add('Contiene una contraseña muy común.');
  }
  if (RegExp(r'(.)\1{2,}').hasMatch(pwd)) {
    bits *= 0.75;
    tips.add('Evita repetir el mismo caracter.');
  }
  if (_hasSequence(lowered)) {
    bits *= 0.75;
    tips.add('Evita secuencias como abc o 123.');
  }
  final unique = pwd.split('').toSet().length;
  if (unique < pwd.length * 0.5) bits *= 0.8;
  if (pwd.length < 12) tips.add('Usa al menos 12 caracteres.');
  if (!pwd.contains(RegExp(r'[A-Z]')) || !pwd.contains(RegExp(r'[a-z]'))) {
    tips.add('Mezcla mayúsculas y minúsculas.');
  }
  if (!pwd.contains(RegExp(r'[0-9]'))) tips.add('Agrega números.');
  if (!pwd.contains(RegExp(r'[^A-Za-z0-9]'))) tips.add('Agrega símbolos.');
  return Analysis(bits, tips);
}

bool _hasSequence(String s) {
  for (var i = 0; i + 2 < s.length; i++) {
    final a = s.codeUnitAt(i), b = s.codeUnitAt(i + 1), c = s.codeUnitAt(i + 2);
    if ((b - a == 1 && c - b == 1) || (a - b == 1 && b - c == 1)) return true;
  }
  return false;
}

/// Tiempo aproximado de fuerza bruta a 10 mil millones de intentos por segundo.
String crackTime(double bits) {
  final seconds = pow(2, bits) / 1e10 / 2;
  if (seconds < 1) return 'al instante';
  if (seconds < 60) return '${seconds.round()} segundos';
  if (seconds < 3600) return '${(seconds / 60).round()} minutos';
  if (seconds < 86400) return '${(seconds / 3600).round()} horas';
  if (seconds < 86400 * 365) return '${(seconds / 86400).round()} días';
  final years = seconds / (86400 * 365);
  if (years < 1e3) return '${years.round()} años';
  if (years < 1e6) return '${(years / 1e3).round()} mil años';
  if (years < 1e9) return '${(years / 1e6).round()} millones de años';
  return 'más que la edad del universo';
}
