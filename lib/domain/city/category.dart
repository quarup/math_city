/// The four roles a building can play in a city. See prd.md *City Builder*
/// for what each one contributes to growth.
enum BuildingCategory {
  housing,
  services,
  commercial,
  entertainment
  ;

  String get displayName => switch (this) {
    BuildingCategory.housing => 'Homes',
    BuildingCategory.services => 'Services',
    BuildingCategory.commercial => 'Commercial',
    BuildingCategory.entertainment => 'Entertainment',
  };
}
