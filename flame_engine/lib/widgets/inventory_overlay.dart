import 'package:flutter/material.dart';
import '../models/inventory.dart';
import '../models/inventory_item.dart';

/// Overlay widget that displays the player's inventory and equipment
class InventoryOverlay extends StatefulWidget {
  final Inventory inventory;
  final VoidCallback onClose;

  const InventoryOverlay({
    super.key,
    required this.inventory,
    required this.onClose,
  });

  @override
  State<InventoryOverlay> createState() => _InventoryOverlayState();
}

class _InventoryOverlayState extends State<InventoryOverlay> {
  InventoryItem? selectedItem;
  ItemCategory? filterCategory;
  EquipmentType? filterEquipmentType;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.7),
      child: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxWidth: 800),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.amber.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStats(),
                        _buildEquipmentSection(),
                        const Divider(color: Colors.white24),
                        _buildFilterBar(),
                        _buildInventoryGrid(),
                        if (selectedItem != null) _buildItemDetails(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF2d2d2d),
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Row(
        children: [
          const Icon(Icons.backpack, color: Colors.amber, size: 24),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'Inventory',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.inventory.isFull 
                  ? Colors.red.withOpacity(0.3) 
                  : Colors.white10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.inventory.isFull ? Colors.red : Colors.white24,
              ),
            ),
            child: Text(
              '${widget.inventory.usedSlots}/${widget.inventory.maxSlots}',
              style: TextStyle(
                color: widget.inventory.isFull ? Colors.red : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: widget.onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final stats = widget.inventory.getTotalStats();
    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: stats.entries.map((entry) {
          final isPositive = entry.value > 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPositive
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${entry.key}: ${isPositive ? "+" : ""}${entry.value}',
              style: TextStyle(
                color: isPositive ? Colors.green : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEquipmentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Equipment',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildWeaponSlot()),
              const SizedBox(width: 12),
              Expanded(child: _buildArmorSlot()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeaponSlot() {
    final item = widget.inventory.equippedWeapon;

    return GestureDetector(
      onTap: item != null
          ? () {
              setState(() {
                widget.inventory.unequipWeapon();
                selectedItem = null;
              });
            }
          : null,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF2d2d2d),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: item != null
                ? Color(item.categoryColor).withOpacity(0.7)
                : Colors.white24,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (item != null)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _buildItemIcon(item),
                ),
              )
            else
              const Expanded(
                child: Icon(Icons.sports_martial_arts, color: Colors.white24, size: 48),
              ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFF1a1a1a),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(6)),
              ),
              child: Center(
                child: Text(
                  item?.name ?? 'Weapon',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArmorSlot() {
    final item = widget.inventory.equippedArmor;

    return GestureDetector(
      onTap: item != null
          ? () {
              setState(() {
                widget.inventory.unequipArmor();
                selectedItem = null;
              });
            }
          : null,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF2d2d2d),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: item != null
                ? Color(item.categoryColor).withOpacity(0.7)
                : Colors.white24,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (item != null)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _buildItemIcon(item),
                ),
              )
            else
              const Expanded(
                child: Icon(Icons.shield, color: Colors.white24, size: 48),
              ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFF1a1a1a),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(6)),
              ),
              child: Center(
                child: Text(
                  item?.name ?? 'Armor',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', null, null),
            const SizedBox(width: 8),
            _buildFilterChip('Weapons', ItemCategory.equipment, EquipmentType.weapon),
            const SizedBox(width: 8),
            _buildFilterChip('Armor', ItemCategory.equipment, EquipmentType.armor),
            const SizedBox(width: 8),
            _buildFilterChip('Consumables', ItemCategory.consumable, null),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, ItemCategory? category, EquipmentType? equipType) {
    final isSelected = filterCategory == category && filterEquipmentType == equipType;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            filterCategory = category;
            filterEquipmentType = equipType;
          } else {
            filterCategory = null;
            filterEquipmentType = null;
          }
        });
      },
      backgroundColor: const Color(0xFF2d2d2d),
      selectedColor: Colors.amber.withOpacity(0.3),
      labelStyle: TextStyle(
        color: isSelected ? Colors.amber : Colors.white70,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? Colors.amber : Colors.white24,
      ),
    );
  }

  Widget _buildInventoryGrid() {
    var items = widget.inventory.items;

    // Apply filter
    if (filterCategory != null) {
      items = items.where((item) => item.category == filterCategory).toList();
      // Additional filter for equipment type
      if (filterEquipmentType != null) {
        items = items.where((item) => item.equipmentType == filterEquipmentType).toList();
      }
    }

    if (items.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        child: const Text(
          'No items',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildInventoryItem(item);
      },
    );
  }

  Widget _buildInventoryItem(InventoryItem item) {
    final isSelected = selectedItem?.id == item.id;
    final isEquipped = widget.inventory.isEquipped(item.id);

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedItem = isSelected ? null : item;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2d2d2d),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.amber
                : Color(item.categoryColor).withOpacity(0.5),
            width: isSelected ? 3 : 2,
          ),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: _buildItemIcon(item)),
                if (item.quantity > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'x${item.quantity}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (isEquipped)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemIcon(InventoryItem item) {
    if (item.iconPath != null) {
      return Image.asset(
        item.iconPath!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildDefaultIcon(item),
      );
    }
    return _buildDefaultIcon(item);
  }

  Widget _buildDefaultIcon(InventoryItem item) {
    IconData icon;
    if (item.isEquipment) {
      switch (item.equipmentType!) {
        case EquipmentType.weapon:
          icon = Icons.sports_martial_arts;
          break;
        case EquipmentType.armor:
          icon = Icons.shield;
          break;
      }
    } else {
      icon = Icons.healing;
    }

    return Icon(
      icon,
      color: Color(item.categoryColor),
      size: 36,
    );
  }

  Widget _buildItemDetails() {
    final item = selectedItem!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF2d2d2d),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        color: Color(item.categoryColor),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.isEquipment 
                          ? item.equipmentType!.displayName
                          : item.category.displayName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Equipment actions
              if (item.isEquipment && !widget.inventory.isEquipped(item.id)) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      widget.inventory.equipItem(item);
                      selectedItem = null;
                    });
                  },
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  label: const Text('Equip'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.withOpacity(0.3),
                    foregroundColor: Colors.green,
                  ),
                ),
              ] else if (widget.inventory.isEquipped(item.id)) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      if (item.equipmentType == EquipmentType.weapon) {
                        widget.inventory.unequipWeapon();
                      } else {
                        widget.inventory.unequipArmor();
                      }
                      selectedItem = null;
                    });
                  },
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  label: const Text('Unequip'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.withOpacity(0.3),
                    foregroundColor: Colors.orange,
                  ),
                ),
              ],
              // Consumable actions
              if (item.isConsumable) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      widget.inventory.useConsumable(item.id);
                      selectedItem = null;
                    });
                    // You can add visual feedback or effects here
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Used ${item.name}'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.local_drink, size: 16),
                  label: const Text('Use'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.withOpacity(0.3),
                    foregroundColor: Colors.blue,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.description,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (item.statModifiers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: item.statModifiers.entries.map((entry) {
                final isPositive = entry.value > 0;
                return Text(
                  '${entry.key}: ${isPositive ? "+" : ""}${entry.value}',
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
