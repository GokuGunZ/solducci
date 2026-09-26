class CsvColumnPreset {
  final String id;
  final String name;
  final String dateColumnName;
  final String descriptionColumnName;
  final String? amountColumnName; // Colonna importo singolo (+ entrata, - uscita)
  final String? expenseColumnName; // Colonna dedicata uscite/dare
  final String? incomeColumnName; // Colonna dedicata entrate/avere
  final String dateFormat;
  final String decimalSeparator;
  final String delimiter;

  const CsvColumnPreset({
    required this.id,
    required this.name,
    required this.dateColumnName,
    required this.descriptionColumnName,
    this.amountColumnName,
    this.expenseColumnName,
    this.incomeColumnName,
    this.dateFormat = 'dd/MM/yyyy',
    this.decimalSeparator = ',',
    this.delimiter = ';',
  });

  bool get hasSingleAmountColumn => amountColumnName != null && amountColumnName!.isNotEmpty;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'dateColumnName': dateColumnName,
    'descriptionColumnName': descriptionColumnName,
    'amountColumnName': amountColumnName,
    'expenseColumnName': expenseColumnName,
    'incomeColumnName': incomeColumnName,
    'dateFormat': dateFormat,
    'decimalSeparator': decimalSeparator,
    'delimiter': delimiter,
  };

  factory CsvColumnPreset.fromMap(Map<String, dynamic> map) => CsvColumnPreset(
    id: map['id'] as String,
    name: map['name'] as String,
    dateColumnName: map['dateColumnName'] as String,
    descriptionColumnName: map['descriptionColumnName'] as String,
    amountColumnName: map['amountColumnName'] as String?,
    expenseColumnName: map['expenseColumnName'] as String?,
    incomeColumnName: map['incomeColumnName'] as String?,
    dateFormat: map['dateFormat'] as String? ?? 'dd/MM/yyyy',
    decimalSeparator: map['decimalSeparator'] as String? ?? ',',
    delimiter: map['delimiter'] as String? ?? ';',
  );

  // Preset nativi pronti all'uso
  static const bnl = CsvColumnPreset(
    id: 'bnl',
    name: 'BNL (Gruppo BNP Paribas)',
    dateColumnName: 'Data operazione',
    descriptionColumnName: 'Causale / Descrizione operazione',
    amountColumnName: 'Importo (EUR)',
    dateFormat: 'dd/MM/yyyy',
    decimalSeparator: ',',
    delimiter: ';',
  );

  static const genericItalian = CsvColumnPreset(
    id: 'generic_it',
    name: 'Generico Italiano',
    dateColumnName: 'Data',
    descriptionColumnName: 'Descrizione',
    amountColumnName: 'Importo',
    dateFormat: 'dd/MM/yyyy',
    decimalSeparator: ',',
    delimiter: ';',
  );

  static const revolut = CsvColumnPreset(
    id: 'revolut',
    name: 'Revolut',
    dateColumnName: 'Started Date',
    descriptionColumnName: 'Description',
    amountColumnName: 'Amount',
    dateFormat: 'yyyy-MM-dd',
    decimalSeparator: '.',
    delimiter: ',',
  );

  static const defaultPresets = [bnl, genericItalian, revolut];
}
