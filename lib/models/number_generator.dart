import 'dart:math';

class NumberGenerator {
  final int numParts;
  final Map<int, int> limits = {
    2: 6000,
    3: 3333,
    4: 2500,
    6: 1666,
  };

  late final int limit;
  final Set<String> generatedNumbers = {}; // Para evitar repetições horizontais
  final Set<String> verticalValues = {}; // Para evitar repetições verticais

  NumberGenerator(this.numParts) {
    if (!limits.containsKey(numParts)) {
      throw ArgumentError("Número de pedaços inválido. Deve ser 2, 3, 4 ou 6.");
    }
    limit = limits[numParts]!;
  }

  List<String> generateNumbers() {
    if (numParts * limit > 9999 * numParts) {
      throw ArgumentError(
          "Limite de combinações excedido. Tente com menos pedaços ou menor limite.");
    }

    List<String> result = [];
    Random random = Random();

    while (result.length < limit) {
      List<String> parts = [];

      // Gera os pedaços do número
      for (int i = 0; i < numParts; i++) {
        String value;
        do {
          value = (random.nextInt(9000) + 1000).toString(); // Gera entre 1000 e 9999
        } while (verticalValues.contains(value)); // Garante unicidade vertical
        verticalValues.add(value);
        parts.add(value);
      }

      // Forma o número completo
      String formattedNumber = parts.join('/');

      if (!generatedNumbers.contains(formattedNumber)) {
        generatedNumbers.add(formattedNumber); // Adiciona o número se for único
        result.add(formattedNumber);
      }
    }

    return result;
  }
}