import 'inventory_item.dart';

/// Manages a player's inventory and equipped items
class Inventory {
  /// Maximum number of inventory slots
  final int maxSlots;

  /// All items in the inventory
  final List<InventoryItem> items;

  /// Equipped weapon
  InventoryItem? equippedWeapon;

  /// Equipped armor
  InventoryItem? equippedArmor;

  Inventory({
    this.maxSlots = 20,
  }) : items = [];

  /// Get number of used slots
  int get usedSlots => items.fold(0, (sum, item) => sum + (item.isStackable ? 1 : item.quantity));

  /// Check if inventory is full
  bool get isFull => usedSlots >= maxSlots;

  /// Add item to inventory
  bool addItem(InventoryItem item) {
    // Check if we can stack it with existing item (consumables only)
    if (item.isStackable) {
      try {
        final existingItem = items.firstWhere((i) => i.id == item.id);
        existingItem.quantity += item.quantity;
        return true;
      } catch (e) {
        // Item not found, will add as new
      }
    }

    // Check if we have space
    if (isFull) {
      return false;
    }

    // Add new item
    items.add(item);
    return true;
  }

  /// Remove item from inventory
  bool removeItem(String itemId, {int quantity = 1}) {
    final itemIndex = items.indexWhere((i) => i.id == itemId);
    if (itemIndex == -1) {
      return false;
    }

    final item = items[itemIndex];
    if (item.quantity <= quantity) {
      items.removeAt(itemIndex);
    } else {
      item.quantity -= quantity;
    }

    return true;
  }

  /// Get item by ID
  InventoryItem? getItem(String itemId) {
    try {
      return items.firstWhere((i) => i.id == itemId);
    } catch (e) {
      return null;
    }
  }

  /// Check if inventory contains item
  bool hasItem(String itemId) {
    return items.any((i) => i.id == itemId);
  }

  /// Equip an item
  bool equipItem(InventoryItem item) {
    if (!item.isEquipment) {
      return false;
    }

    // Unequip existing item if any
    if (item.equipmentType == EquipmentType.weapon && equippedWeapon != null) {
      unequipWeapon();
    } else if (item.equipmentType == EquipmentType.armor && equippedArmor != null) {
      unequipArmor();
    }

    // Remove from inventory and equip
    final removed = removeItem(item.id);
    if (removed) {
      if (item.equipmentType == EquipmentType.weapon) {
        equippedWeapon = item;
      } else {
        equippedArmor = item;
      }
      return true;
    }

    return false;
  }

  /// Unequip weapon
  bool unequipWeapon() {
    if (equippedWeapon == null) {
      return false;
    }

    final added = addItem(equippedWeapon!);
    if (added) {
      equippedWeapon = null;
      return true;
    }

    return false;
  }

  /// Unequip armor
  bool unequipArmor() {
    if (equippedArmor == null) {
      return false;
    }

    final added = addItem(equippedArmor!);
    if (added) {
      equippedArmor = null;
      return true;
    }

    return false;
  }

  /// Check if an item is equipped
  bool isEquipped(String itemId) {
    return (equippedWeapon?.id == itemId) || (equippedArmor?.id == itemId);
  }

  /// Get total stat modifiers from all equipped items
  Map<String, int> getTotalStats() {
    final stats = <String, int>{};

    final equipped = [equippedWeapon, equippedArmor].whereType<InventoryItem>();
    for (final item in equipped) {
      for (final entry in item.statModifiers.entries) {
        stats[entry.key] = (stats[entry.key] ?? 0) + entry.value;
      }
    }

    return stats;
  }

  /// Sort inventory by category
  void sortInventory() {
    items.sort((a, b) {
      final categoryCompare = a.category.index.compareTo(b.category.index);
      if (categoryCompare != 0) return categoryCompare;
      // Within equipment, sort weapons before armor
      if (a.isEquipment && b.isEquipment) {
        return a.equipmentType!.index.compareTo(b.equipmentType!.index);
      }
      return 0;
    });
  }

  /// Get items by category
  List<InventoryItem> getItemsByCategory(ItemCategory category) {
    return items.where((item) => item.category == category).toList();
  }

  /// Get all equipment items
  List<InventoryItem> getEquipmentItems() {
    return items.where((item) => item.isEquipment).toList();
  }

  /// Get all consumable items
  List<InventoryItem> getConsumableItems() {
    return items.where((item) => item.isConsumable).toList();
  }

  /// Use a consumable item
  bool useConsumable(String itemId) {
    final item = getItem(itemId);
    if (item == null || !item.isConsumable) {
      return false;
    }

    // Remove one from inventory
    return removeItem(itemId, quantity: 1);
  }

  /// Clear all items
  void clear() {
    items.clear();
    equippedWeapon = null;
    equippedArmor = null;
  }
}
