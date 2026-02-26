import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../models/player.dart';

/// Overlay widget that displays the player's inventory and equipment
class InventoryOverlay extends StatefulWidget {
  final Player player;
  final VoidCallback onClose;

  const InventoryOverlay({
    super.key,
    required this.player,
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
                color: const Color(0xFF00d9ff).withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00d9ff).withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      bottom: 80,
                    ), // Prevent floating button overlap
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
          const Icon(Icons.inventory_2, color: Color(0xFF00d9ff), size: 24),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'INVENTORY',
              style: TextStyle(
                color: Color(0xFF00d9ff),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.player.inventory.isFull
                  ? Colors.red.withOpacity(0.3)
                  : Colors.white10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.player.inventory.isFull
                    ? Colors.red
                    : Colors.white24,
              ),
            ),
            child: Text(
              '${widget.player.inventory.usedSlots}/${widget.player.inventory.maxSlots}',
              style: TextStyle(
                color: widget.player.inventory.isFull
                    ? Colors.red
                    : Colors.white70,
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
    final character = widget.player.character;
    if (character == null) {
      return const SizedBox.shrink();
    }

    final equipmentStats = widget.player.inventory.getTotalStats();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2d2d2d).withOpacity(0.5),
        border: const Border(
          bottom: BorderSide(color: Colors.white12, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Character Stats',
            style: TextStyle(
              color: Color(0xFF00d9ff),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  icon: Icons.favorite,
                  iconColor: Colors.red,
                  label: 'Health',
                  base: character.health,
                  max: character.maxHealth,
                  bonus: equipmentStats['maxHealth'] ?? 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatBox(
                  icon: Icons.flash_on,
                  iconColor: Colors.orange,
                  label: 'Attack',
                  base: character.attack,
                  bonus: equipmentStats['attack'] ?? 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatBox(
                  icon: Icons.shield,
                  iconColor: Colors.blue,
                  label: 'Defense',
                  base: character.defense,
                  bonus: equipmentStats['defense'] ?? 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required Color iconColor,
    required String label,
    required int base,
    int? max,
    required int bonus,
  }) {
    final total = base + bonus;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          const SizedBox(height: 2),
          if (max != null)
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: '$base',
                    style: const TextStyle(color: Colors.white),
                  ),
                  TextSpan(
                    text: '/${max + bonus}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          else
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: '$base',
                    style: const TextStyle(color: Colors.white),
                  ),
                  if (bonus != 0)
                    TextSpan(
                      text: bonus > 0 ? ' +$bonus' : ' $bonus',
                      style: TextStyle(
                        color: bonus > 0 ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          if (bonus != 0 && max == null)
            Text(
              '= $total',
              style: const TextStyle(
                color: Color(0xFF00d9ff),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
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
              color: Color(0xFF00d9ff),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
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
    final item = widget.player.inventory.equippedWeapon;

    return DragTarget<InventoryItem>(
      onWillAcceptWithDetails: (details) {
        // Only accept weapon equipment items
        return details.data.equipmentType == EquipmentType.weapon;
      },
      onAcceptWithDetails: (details) {
        setState(() {
          widget.player.inventory.equipItem(details.data);
          selectedItem = null;
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return GestureDetector(
          onTap: item != null
              ? () {
                  setState(() {
                    widget.player.inventory.unequipWeapon();
                    selectedItem = null;
                  });
                }
              : null,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: isHovering
                  ? const Color(0xFF00d9ff).withValues(alpha: 0.2)
                  : const Color(0xFF2d2d2d),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isHovering
                    ? const Color(0xFF00d9ff)
                    : item != null
                    ? Color(item.categoryColor).withOpacity(0.7)
                    : Colors.white24,
                width: isHovering ? 3 : 2,
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
                    child: Icon(
                      Icons.flash_on,
                      color: Colors.white24,
                      size: 48,
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1a1a1a),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(6),
                    ),
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
      },
    );
  }

  Widget _buildArmorSlot() {
    final item = widget.player.inventory.equippedArmor;

    return DragTarget<InventoryItem>(
      onWillAcceptWithDetails: (details) {
        // Only accept armor equipment items
        return details.data.equipmentType == EquipmentType.armor;
      },
      onAcceptWithDetails: (details) {
        setState(() {
          widget.player.inventory.equipItem(details.data);
          selectedItem = null;
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return GestureDetector(
          onTap: item != null
              ? () {
                  setState(() {
                    widget.player.inventory.unequipArmor();
                    selectedItem = null;
                  });
                }
              : null,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: isHovering
                  ? const Color(0xFF00d9ff).withValues(alpha: 0.2)
                  : const Color(0xFF2d2d2d),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isHovering
                    ? const Color(0xFF00d9ff)
                    : item != null
                    ? Color(item.categoryColor).withOpacity(0.7)
                    : Colors.white24,
                width: isHovering ? 3 : 2,
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
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(6),
                    ),
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
      },
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
            _buildFilterChip(
              'Weapons',
              ItemCategory.equipment,
              EquipmentType.weapon,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Armor',
              ItemCategory.equipment,
              EquipmentType.armor,
            ),
            const SizedBox(width: 8),
            _buildFilterChip('Consumables', ItemCategory.consumable, null),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    ItemCategory? category,
    EquipmentType? equipType,
  ) {
    final isSelected =
        filterCategory == category && filterEquipmentType == equipType;

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
      selectedColor: const Color(0xFF00d9ff).withValues(alpha: 0.3),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF00d9ff) : Colors.white70,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF00d9ff) : Colors.white24,
      ),
    );
  }

  Widget _buildInventoryGrid() {
    var items = widget.player.inventory.items;

    // Apply filter
    if (filterCategory != null) {
      items = items.where((item) => item.category == filterCategory).toList();
      // Additional filter for equipment type
      if (filterEquipmentType != null) {
        items = items
            .where((item) => item.equipmentType == filterEquipmentType)
            .toList();
      }
    }

    if (items.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        child: const Text('No items', style: TextStyle(color: Colors.white38)),
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
    final isEquipped = widget.player.inventory.isEquipped(item.id);

    // Build the item widget
    final itemWidget = Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2d2d2d),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF00d9ff)
              : Color(item.categoryColor).withValues(alpha: 0.5),
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
              child: Icon(Icons.check_circle, color: Colors.green, size: 16),
            ),
        ],
      ),
    );

    // Wrap equipment items with drag functionality
    if (item.isEquipment && !isEquipped) {
      return LongPressDraggable<InventoryItem>(
        data: item,
        feedback: Transform.scale(
          scale: 1.2,
          child: Opacity(
            opacity: 0.8,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 80,
                height: 94,
                decoration: BoxDecoration(
                  color: const Color(0xFF2d2d2d),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00d9ff), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00d9ff).withValues(alpha: 0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _buildItemIcon(item),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: itemWidget),
        child: GestureDetector(
          onTap: () {
            setState(() {
              selectedItem = isSelected ? null : item;
            });
          },
          child: itemWidget,
        ),
      );
    }

    // Non-equipment items or equipped items just use tap
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedItem = isSelected ? null : item;
        });
      },
      child: itemWidget,
    );
  }

  Widget _buildItemIcon(InventoryItem item) {
    if (item.iconPath != null) {
      return Image.asset(
        item.iconPath!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _buildDefaultIcon(item),
      );
    }
    return _buildDefaultIcon(item);
  }

  Widget _buildDefaultIcon(InventoryItem item) {
    IconData icon;
    if (item.isEquipment) {
      switch (item.equipmentType!) {
        case EquipmentType.weapon:
          icon = Icons.flash_on;
          break;
        case EquipmentType.armor:
          icon = Icons.shield;
          break;
      }
    } else {
      icon = Icons.healing;
    }

    return Icon(icon, color: Color(item.categoryColor), size: 36);
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
              if (item.isEquipment &&
                  !widget.player.inventory.isEquipped(item.id)) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      widget.player.inventory.equipItem(item);
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
              ] else if (widget.player.inventory.isEquipped(item.id)) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      if (item.equipmentType == EquipmentType.weapon) {
                        widget.player.inventory.unequipWeapon();
                      } else {
                        widget.player.inventory.unequipArmor();
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
                      widget.player.inventory.useConsumable(item.id);
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
