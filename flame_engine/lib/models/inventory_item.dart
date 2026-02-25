/// Represents an item that can be in a player's inventory
class InventoryItem {
  /// Unique identifier for the item type
  final String id;

  /// Display name of the item
  final String name;

  /// Description of the item
  final String description;

  /// Item category/type
  final ItemCategory category;

  /// Equipment type (if this is equipment)
  final EquipmentType? equipmentType;

  /// Stat modifiers this item provides
  final Map<String, int> statModifiers;

  /// Icon/image path for the item
  final String? iconPath;

  /// Quantity of this item (for stackable items)
  int quantity;

  InventoryItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.equipmentType,
    this.statModifiers = const {},
    this.iconPath,
    this.quantity = 1,
  })  : assert(
          category == ItemCategory.consumable || equipmentType != null,
          'Equipment items must have an equipmentType',
        );

  /// Check if item is equipment
  bool get isEquipment => category == ItemCategory.equipment;

  /// Check if item is consumable
  bool get isConsumable => category == ItemCategory.consumable;

  /// Check if item is stackable (consumables are stackable)
  bool get isStackable => isConsumable;

  /// Get category color for UI
  int get categoryColor {
    if (isEquipment) {
      switch (equipmentType!) {
        case EquipmentType.weapon:
          return 0xFFFF4444; // Red
        case EquipmentType.armor:
          return 0xFF4444FF; // Blue
      }
    } else {
      return 0xFF44FF44; // Green for consumables
    }
  }

  /// Create a copy of this item
  InventoryItem copyWith({
    String? id,
    String? name,
    String? description,
    ItemCategory? category,
    EquipmentType? equipmentType,
    Map<String, int>? statModifiers,
    String? iconPath,
    int? quantity,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      equipmentType: equipmentType ?? this.equipmentType,
      statModifiers: statModifiers ?? this.statModifiers,
      iconPath: iconPath ?? this.iconPath,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  String toString() {
    if (isEquipment) {
      return '$name (x$quantity) - ${equipmentType!.displayName}';
    } else {
      return '$name (x$quantity) - Consumable';
    }
  }
}

/// Item categories
enum ItemCategory {
  equipment,
  consumable;

  String get displayName {
    switch (this) {
      case ItemCategory.equipment:
        return 'Equipment';
      case ItemCategory.consumable:
        return 'Consumable';
    }
  }
}

/// Equipment types
enum EquipmentType {
  weapon,
  armor;

  String get displayName {
    switch (this) {
      case EquipmentType.weapon:
        return 'Weapon';
      case EquipmentType.armor:
        return 'Armor';
    }
  }
}
