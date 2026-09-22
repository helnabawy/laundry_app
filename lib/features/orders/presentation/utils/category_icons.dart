import '../../../../core/design/design.dart';

/// Maps a `ServiceCategory.id` to its glyph in the care family.
CareGlyph categoryGlyph(String categoryId) => switch (categoryId) {
  'cat-clothes' => CareGlyph.clothes,
  'cat-textiles' => CareGlyph.textiles,
  'cat-carpets' => CareGlyph.carpets,
  'cat-curtains' => CareGlyph.curtains,
  _ => CareGlyph.clothes,
};
