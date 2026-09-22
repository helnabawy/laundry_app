import '../../../../core/design/design.dart';

/// The standardised care symbols that truthfully describe a sub-service.
///
/// This is the only place in the app the GINETEX set appears: on the invoice,
/// reporting the treatment the facility actually applied. An unrecognised
/// service returns nothing rather than guessing — the app never implies care
/// the service did not give.
List<CareSymbol> treatmentSymbols(String subServiceId) =>
    switch (subServiceId) {
      'sub-wash-only' => const [CareSymbol.wash, CareSymbol.dry],
      'sub-wash-iron' => const [
        CareSymbol.wash,
        CareSymbol.dry,
        CareSymbol.iron,
      ],
      'sub-iron-only' => const [CareSymbol.iron],
      'sub-full-service' => const [
        CareSymbol.wash,
        CareSymbol.dry,
        CareSymbol.iron,
        CareSymbol.professional,
      ],
      'sub-textiles-wash' => const [
        CareSymbol.wash,
        CareSymbol.dry,
        CareSymbol.iron,
      ],
      'sub-carpet-deep' => const [CareSymbol.professional, CareSymbol.dry],
      'sub-curtain-full' => const [
        CareSymbol.wash,
        CareSymbol.dry,
        CareSymbol.iron,
      ],
      _ => const [],
    };

String careSymbolLabel(CareSymbol symbol) => switch (symbol) {
  CareSymbol.wash => 'Wash',
  CareSymbol.bleach => 'Bleach',
  CareSymbol.dry => 'Dry',
  CareSymbol.iron => 'Iron',
  CareSymbol.professional => 'Professional care',
};
