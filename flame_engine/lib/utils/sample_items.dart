import '../models/inventory_item.dart';

/// Sample items for testing the inventory system
class SampleItems {
  // Weapons
  static InventoryItem pistol() => InventoryItem(
        id: 'pistol',
        name: 'Pistol',
        description: 'A reliable sidearm. Standard issue for field agents.',
        category: ItemCategory.equipment,
        equipmentType: EquipmentType.weapon,
        statModifiers: {'attack': 3},
        iconPath: 'assets/images/inventory/Pistol.png',
      );

  static InventoryItem tacticalGlove() => InventoryItem(
        id: 'tactical_glove',
        name: 'Tactical Glove',
        description: 'Enhanced combat gloves with reinforced knuckles.',
        category: ItemCategory.equipment,
        equipmentType: EquipmentType.weapon,
        statModifiers: {'attack': 2, 'defense': 1},
        iconPath: 'assets/images/inventory/Glove.png',
      );

  // Armor
  static InventoryItem helmet() => InventoryItem(
        id: 'helmet',
        name: 'Combat Helmet',
        description: 'Protects your head from environmental hazards and attacks.',
        category: ItemCategory.equipment,
        equipmentType: EquipmentType.armor,
        statModifiers: {'defense': 3},
        iconPath: 'assets/images/inventory/Helmet.png',
      );

  static InventoryItem oxygenTank() => InventoryItem(
        id: 'oxygen_tank',
        name: 'Oxygen Tank',
        description: 'Heavy protective vest with integrated life support.',
        category: ItemCategory.equipment,
        equipmentType: EquipmentType.armor,
        statModifiers: {'defense': 5, 'maxHealth': 5},
        iconPath: 'assets/images/inventory/Tank.png',
      );

  // Consumables
  static InventoryItem food({int quantity = 1}) => InventoryItem(
        id: 'food',
        name: 'Ration Pack',
        description: 'Emergency food ration. Restores 20 health points.',
        category: ItemCategory.consumable,
        quantity: quantity,
        iconPath: 'assets/images/inventory/Food.png',
      );

  static InventoryItem medkit({int quantity = 1}) => InventoryItem(
        id: 'medkit',
        name: 'Medical Kit',
        description: 'Advanced medical supplies. Restores 50 health points.',
        category: ItemCategory.consumable,
        quantity: quantity,
      );

  // Utility Items (Equipment that don't fit weapon/armor)
  static InventoryItem flashlight() => InventoryItem(
        id: 'flashlight',
        name: 'Tactical Flashlight',
        description: 'Illuminates dark areas and reveals hidden objects.',
        category: ItemCategory.equipment,
        equipmentType: EquipmentType.weapon, // Counts as utility weapon
        statModifiers: {'attack': 1},
        iconPath: 'assets/images/inventory/Flashlight.png',
      );

  static InventoryItem radio() => InventoryItem(
        id: 'radio',
        name: 'Comms Radio',
        description: 'Communication device that boosts team coordination.',
        category: ItemCategory.equipment,
        equipmentType: EquipmentType.armor, // Counts as utility armor
        statModifiers: {'defense': 2, 'maxHealth': 2},
        iconPath: 'assets/images/inventory/Radio.png',
      );

  static InventoryItem device() => InventoryItem(
        id: 'device',
        name: 'Multi-Tool Device',
        description: 'Versatile electronic device with multiple functions.',
        category: ItemCategory.equipment,
        equipmentType: EquipmentType.weapon,
        statModifiers: {'attack': 4, 'maxHealth': 3},
        iconPath: 'assets/images/inventory/Device.png',
      );

  /// Get a starter inventory for new players
  static List<InventoryItem> getStarterItems() {
    return [
      pistol(),
      helmet(),
      food(quantity: 3),
    ];
  }

  /// Get a random item for loot drops
  static InventoryItem getRandomItem() {
    final items = [
      pistol(),
      tacticalGlove(),
      helmet(),
      oxygenTank(),
      flashlight(),
      radio(),
      device(),
      food(),
      medkit(),
    ];
    items.shuffle();
    return items.first;
  }

  /// Get all available items
  static List<InventoryItem> getAllItems() {
    return [
      pistol(),
      tacticalGlove(),
      helmet(),
      oxygenTank(),
      flashlight(),
      radio(),
      device(),
      food(quantity: 5),
      medkit(quantity: 3),
    ];
  }
}
