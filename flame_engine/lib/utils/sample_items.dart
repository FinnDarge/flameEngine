import '../models/inventory_item.dart';

/// Sample items for testing the inventory system
class SampleItems {
  // Weapons
  static InventoryItem ironSword() => InventoryItem(
        id: 'iron_sword',
        name: 'Iron Sword',
        description: 'A sturdy blade forged from iron. Good for beginners.',
        category: ItemCategory.equipment,
        equipmentType: EquipmentType.weapon,
        statModifiers: {'attack': 2},
      );

  static InventoryItem steelAxe() => InventoryItem(
        id: 'steel_axe',
        name: 'Steel Axe',
        description: 'A heavy axe that deals devastating blows.',
        category: ItemCategory.equipment,
        equipmentType: EquipmentType.weapon,
        statModifiers: {'attack': 4, 'defense': -1},
      );

  static InventoryItem fireStaff() => InventoryItem(
        id: 'fire_staff',
        name: 'Staff of Flames',
        description: 'A magical staff imbued with the power of fire.',
        category: ItemCategory.equipment,
        equipmentType: EquipmentType.weapon,
        statModifiers: {'attack': 5, 'maxHealth': 2},
      );

  static InventoryItem legendaryBlade() => InventoryItem(
        id: 'legendary_blade',
        name: 'Excalibur',
        description: 'The legendary sword of kings. Its power is unmatched.',
        category: ItemCategory.equipment,
        equipmentType: EquipmentType.weapon,
        statModifiers: {'attack': 10, 'defense': 3, 'maxHealth': 5},
      );

  // Armor
  static InventoryItem leatherArmor() => InventoryItem(
        id: 'leather_armor',
        name: 'Leather Armor',
        description: 'Light armor that provides basic protection.',
        category: ItemCategory.equipment,
        equipmentType: EquipmentType.armor,
        statModifiers: {'defense': 2},
      );

  static InventoryItem steelPlate() => InventoryItem(
        id: 'steel_plate',
        name: 'Steel Plate Armor',
        description: 'Heavy armor that offers excellent protection.',
        category: ItemCategory.equipment,
        equipmentType: EquipmentType.armor,
        statModifiers: {'defense': 5, 'maxHealth': 3},
      );

  static InventoryItem dragonScale() => InventoryItem(
        id: 'dragon_scale_armor',
        name: 'Dragon Scale Armor',
        description: 'Armor crafted from the scales of a mighty dragon.',
        category: ItemCategory.equipment,
        equipmentType: EquipmentType.armor,
        statModifiers: {'defense': 7, 'maxHealth': 5, 'attack': 2},
      );

  // Consumables
  static InventoryItem healthPotion({int quantity = 1}) => InventoryItem(
        id: 'health_potion',
        name: 'Health Potion',
        description: 'Restores 20 health points when used.',
        category: ItemCategory.consumable,
        quantity: quantity,
      );

  static InventoryItem manaPotion({int quantity = 1}) => InventoryItem(
        id: 'mana_potion',
        name: 'Mana Potion',
        description: 'Restores 30 mana points when used.',
        category: ItemCategory.consumable,
        quantity: quantity,
      );

  static InventoryItem elixir({int quantity = 1}) => InventoryItem(
        id: 'elixir',
        name: 'Grand Elixir',
        description: 'Fully restores health and mana when used.',
        category: ItemCategory.consumable,
        quantity: quantity,
      );

  static InventoryItem strengthPotion({int quantity = 1}) => InventoryItem(
        id: 'strength_potion',
        name: 'Strength Potion',
        description: 'Temporarily increases attack power.',
        category: ItemCategory.consumable,
        quantity: quantity,
      );

  static InventoryItem defensePotion({int quantity = 1}) => InventoryItem(
        id: 'defense_potion',
        name: 'Defense Potion',
        description: 'Temporarily increases defense.',
        category: ItemCategory.consumable,
        quantity: quantity,
      );

  /// Get a starter inventory for new players
  static List<InventoryItem> getStarterItems() {
    return [
      ironSword(),
      leatherArmor(),
      healthPotion(quantity: 3),
      manaPotion(quantity: 2),
    ];
  }

  /// Get a random item for loot drops
  static InventoryItem getRandomItem() {
    final items = [
      ironSword(),
      steelAxe(),
      fireStaff(),
      leatherArmor(),
      steelPlate(),
      dragonScale(),
      healthPotion(),
      manaPotion(),
      elixir(),
      strengthPotion(),
      defensePotion(),
    ];
    items.shuffle();
    return items.first;
  }

  /// Get all available items
  static List<InventoryItem> getAllItems() {
    return [
      ironSword(),
      steelAxe(),
      fireStaff(),
      legendaryBlade(),
      leatherArmor(),
      steelPlate(),
      dragonScale(),
      healthPotion(quantity: 5),
      manaPotion(quantity: 5),
      elixir(quantity: 2),
      strengthPotion(quantity: 3),
      defensePotion(quantity: 3),
    ];
  }
}
