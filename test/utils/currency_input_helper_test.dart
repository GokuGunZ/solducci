import 'package:flutter_test/flutter_test.dart';
import 'package:solducci/utils/currency_input_helper.dart';

void main() {
  group('CurrencyInputHelper', () {
    test('parses standard dot decimal numbers', () {
      expect(CurrencyInputHelper.parse('31.4'), 31.4);
      expect(CurrencyInputHelper.parse('0.99'), 0.99);
      expect(CurrencyInputHelper.parse('100.50'), 100.50);
    });

    test('parses comma decimal numbers', () {
      expect(CurrencyInputHelper.parse('31,4'), 31.4);
      expect(CurrencyInputHelper.parse('0,99'), 0.99);
      expect(CurrencyInputHelper.parse('100,50'), 100.50);
    });

    test('parses thousands separators properly', () {
      expect(CurrencyInputHelper.parse('1.250,50'), 1250.50);
      expect(CurrencyInputHelper.parse('1,250.50'), 1250.50);
      expect(CurrencyInputHelper.parse('10 000,00'), 10000.0);
    });

    test('parses integers and handles whitespace and currency symbols', () {
      expect(CurrencyInputHelper.parse('42'), 42.0);
      expect(CurrencyInputHelper.parse(' 50 € '), 50.0);
      expect(CurrencyInputHelper.parse(''), null);
      expect(CurrencyInputHelper.parse(null), null);
      expect(CurrencyInputHelper.parse('abc'), null);
    });
  });
}
