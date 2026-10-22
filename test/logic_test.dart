import 'package:clave_segura/password_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('contrasenas comunes con año son debiles', () {
    expect(analyzePassword('Perro2024').strength.index, lessThanOrEqualTo(Strength.weak.index));
    expect(analyzePassword('password123').strength, Strength.veryWeak);
    expect(analyzePassword('Mexico1990').strength.index, lessThanOrEqualTo(Strength.weak.index));
  });
  test('contrasenas aleatorias son fuertes', () {
    expect(analyzePassword('Tz9-mQvN4xLe-Pw7r').strength.index, greaterThanOrEqualTo(Strength.strong.index));
    for (var i = 0; i < 20; i++) {
      final p = generatePassword(PasswordOptions(length: 16));
      expect(p.length, 16);
      expect(analyzePassword(p).strength.index, greaterThanOrEqualTo(Strength.strong.index));
    }
  });
  test('el generador respeta tipos y longitud', () {
    final o = PasswordOptions(length: 20, upper: false, symbols: false);
    final p = generatePassword(o);
    expect(p.length, 20);
    expect(RegExp(r'^[a-z0-9]+$').hasMatch(p), isTrue);
    expect(RegExp(r'[0-9]').hasMatch(p), isTrue);
  });
  test('frase', () {
    final f = generatePassphrase(words: 5, addNumber: false);
    expect(f.split('-').length, 5);
  });
}
