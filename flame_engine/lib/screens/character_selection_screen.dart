import 'package:flutter/material.dart';
import 'dart:async';
import '../models/character.dart';
import '../models/game_state.dart';
import '../services/nfc_service.dart' show NFCService, kMockNfc;
import '../controllers/session_flow_controller.dart';
import '../services/session_api_service.dart' show ApiRole, SessionPlayer;
import '../widgets/token_and_board_app_bar.dart';
import '../widgets/session_info_footer.dart';

/// Character selection screen for claiming a character
class CharacterSelectionScreen extends StatefulWidget {
  final GameState gameState;
  final NFCService nfcService;
  final SessionFlowController sessionFlow;
  final VoidCallback onCharacterSelected;
  final VoidCallback onBack;

  const CharacterSelectionScreen({
    super.key,
    required this.gameState,
    required this.nfcService,
    required this.sessionFlow,
    required this.onCharacterSelected,
    required this.onBack,
  });

  @override
  State<CharacterSelectionScreen> createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  static const List<String> _frontendRoles = [
    'Vanguard',
    'Controller',
    'Striker',
    'Engineer',
  ];

  bool nfcAvailable = false;
  String nfcStatus = 'Initialising NFC...';
  String? _scannedTagId;
  String? _highlightedRoleUuid; // Track which role to highlight after scan

  // Roles and claims
  List<ApiRole> _availableRoles = [];
  List<String> _claimedRoleUuids = [];
  bool _loadingRoles = false;
  String? _rolesError;

  // Session joining
  bool _joiningSession = false;
  bool _hasJoined = false; // Track if user has already joined the session
  String? _joinError;
  String? _joinedRoleUuid; // Track which role user joined with
  Timer? _sessionPlayersRefreshTimer;

  Map<String, ApiRole> _buildFrontendRoleMap(List<ApiRole> backendRoles) {
    final mappedRoles = <String, ApiRole>{};
    for (final role in backendRoles) {
      final frontendRole = _mapBackendRoleToFrontendRole(role.name);
      if (frontendRole != null && !mappedRoles.containsKey(frontendRole)) {
        mappedRoles[frontendRole] = role;
      }
    }
    return mappedRoles;
  }

  String? _mapBackendRoleToFrontendRole(String backendRoleName) {
    final normalized = backendRoleName.trim().toLowerCase();
    if (normalized.contains('vanguard') || normalized == 'red') {
      return 'Vanguard';
    }
    if (normalized.contains('controller') || normalized == 'purple') {
      return 'Controller';
    }
    if (normalized.contains('striker') || normalized == 'white') {
      return 'Striker';
    }
    if (normalized.contains('engineer') || normalized == 'blue') {
      return 'Engineer';
    }
    return null;
  }

  /// Resolve a human-readable character name from a tag ID.
  /// Checks mock payload first, then falls back to CharacterClass enum.
  String? _resolveCharacterName(String tagId, Map<String, dynamic>? data) {
    // Use name from NFC payload data if present
    final payloadName = data?['characterName'] as String?;
    if (payloadName != null) return payloadName;
    // Fall back to CharacterClass enum match
    for (final cls in CharacterClass.values) {
      if (cls.nfcTagId == tagId) return cls.name;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _initNFC();
    _loadAvailableRoles();
    _startSessionPlayersRefreshTimer();
  }

  void _startSessionPlayersRefreshTimer() {
    _sessionPlayersRefreshTimer?.cancel();
    _sessionPlayersRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        _refreshSessionPlayers();
      },
    );
  }

  Future<void> _refreshSessionPlayers() async {
    final sessionUuid = widget.gameState.sessionUuid;
    if (sessionUuid == null) return;

    try {
      final players = await widget.sessionFlow.getSessionPlayers(sessionUuid);
      final claimedUuids = players.map((p) => p.role).toList();
      final localPlayerUuid = widget.gameState.localApiPlayer?.uuid;
      SessionPlayer? localAssignment;
      if (localPlayerUuid != null) {
        for (final player in players) {
          if (player.player == localPlayerUuid) {
            localAssignment = player;
            break;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        widget.gameState.sessionPlayers = players;
        _claimedRoleUuids = claimedUuids;
        if (localAssignment != null) {
          _hasJoined = true;
          _joinedRoleUuid = localAssignment.role;
          _highlightedRoleUuid ??= localAssignment.role;
        }
      });
    } catch (_) {
      // Keep existing values if refresh fails; next refresh will retry.
    }
  }

  Future<void> _initNFC() async {
    final available = await widget.nfcService.checkAvailability();
    setState(() {
      nfcAvailable = available;
      nfcStatus = available
          ? 'Tap your character figure to the phone'
          : 'NFC Not Available';
    });
    if (available) {
      _startNFCScanning();
    }
  }

  Future<void> _loadAvailableRoles() async {
    final gameUuid = widget.gameState.selectedApiGame?.uuid;
    final sessionUuid = widget.gameState.sessionUuid;

    if (gameUuid == null) {
      setState(() {
        _rolesError = 'No game selected';
      });
      return;
    }

    setState(() {
      _loadingRoles = true;
      _rolesError = null;
    });

    try {
      // Fetch available roles for the game
      final roles = await widget.sessionFlow.getRolesForGame(gameUuid);

      // Fetch claimed roles if we have a session
      List<String> claimedUuids = [];
      List<SessionPlayer> sessionPlayers = [];
      if (sessionUuid != null) {
        sessionPlayers = await widget.sessionFlow.getSessionPlayers(sessionUuid);
        claimedUuids = sessionPlayers.map((p) => p.role).toList();
      }

      // Check if user has already claimed a character
      String? restoredHighlightedRoleUuid;
      String? restoredScannedTagId;
      bool restoredHasJoined = false;

      final character = widget.gameState.localPlayer.character;
      if (character != null) {
        // User has a character, find the matching role
        restoredScannedTagId = character.nfcTagId;
        restoredHasJoined = true;

        final characterClassName = character.characterClass.name;
        for (final role in roles) {
          final mappedRoleName = _mapBackendRoleToFrontendRole(role.name);
          if (mappedRoleName?.toLowerCase() == characterClassName.toLowerCase()) {
            restoredHighlightedRoleUuid = role.uuid;
            print(
              '🔄 Restored joined state: ${character.characterClass.name} -> ${role.name}',
            );
            break;
          }
        }
      }

      setState(() {
        _availableRoles = roles;
        widget.gameState.sessionPlayers = sessionPlayers;
        _claimedRoleUuids = claimedUuids;
        _loadingRoles = false;

        // Restore state if user already joined
        if (restoredHasJoined) {
          _hasJoined = true;
          _highlightedRoleUuid = restoredHighlightedRoleUuid;
          _scannedTagId = restoredScannedTagId;
          _joinedRoleUuid = restoredHighlightedRoleUuid;
          nfcStatus = 'Character locked - already joined session';
        }
      });
    } catch (e) {
      setState(() {
        _rolesError = e.toString();
        _loadingRoles = false;
      });
    }
  }

  void _startNFCScanning() {
    widget.nfcService.startScanning((tagId, data) {
      // Ignore scans if already joined to prevent changing character
      if (_hasJoined) {
        print('🔒 Character selection locked - already joined session');
        return;
      }

      final name = _resolveCharacterName(tagId, data);
      // Release previous character so re-scanning updates the selection
      final prev = widget.gameState.localPlayer.character;
      if (prev != null) {
        widget.gameState.characters.remove(prev);
        widget.gameState.localPlayer.releaseCharacter();
      }
      // Claim the character in game state so downstream screens can use it
      widget.gameState.claimCharacter(tagId);

      // Find the role that corresponds to this character
      String? highlightedRoleUuid;
      String? characterClassName;

      // First, try to find the piece directly by tagId to get the character class
      for (final piece in widget.gameState.apiPieces) {
        if (piece.nfcTagId == tagId) {
          characterClassName = piece.characterClass;
          print(
            '📍 Found piece from tagId: ${piece.name} (characterClass: ${piece.characterClass})',
          );
          break;
        }
      }

      // Fallback: try to get character class from claimed character
      if (characterClassName == null) {
        final character = widget.gameState.localPlayer.character;
        if (character != null) {
          characterClassName = character.characterClass.name;
          print(
            '📍 Found character class from claimed character: $characterClassName',
          );
        }
      }

      // Now match to a role if we have a character class
      if (characterClassName != null) {
        print('🔍 Trying to match "$characterClassName" to available roles:');

        // First try direct name match
        for (final role in _availableRoles) {
          print('   - Checking role: ${role.name} (${role.uuid})');
          final mappedRoleName = _mapBackendRoleToFrontendRole(role.name);
          if (mappedRoleName?.toLowerCase() == characterClassName.toLowerCase()) {
            highlightedRoleUuid = role.uuid;
            print(
              '✅ MATCHED! Character class "$characterClassName" to role "${role.name}" (${role.uuid})',
            );
            break;
          }
        }

        // If no direct match, try piece color to role name mapping
        if (highlightedRoleUuid == null) {
          final roleNameForPiece = _getPieceColorToRoleName(characterClassName);
          print(
            '🔄 No direct match. Trying piece color mapping: "$characterClassName" -> "$roleNameForPiece"',
          );

          if (roleNameForPiece != null) {
            for (final role in _availableRoles) {
              final mappedRoleName = _mapBackendRoleToFrontendRole(role.name);
              if (mappedRoleName?.toLowerCase() == roleNameForPiece.toLowerCase()) {
                highlightedRoleUuid = role.uuid;
                print(
                  '✅ MAPPED! Piece color "$characterClassName" -> role "${role.name}" (${role.uuid})',
                );
                break;
              }
            }
          }
        }

        if (highlightedRoleUuid == null) {
          print('❌ NO MATCH FOUND for character class: $characterClassName');
        }
      } else {
        print('⚠️ Could not determine character class for tagId: $tagId');
      }

      setState(() {
        _scannedTagId = tagId;
        _highlightedRoleUuid = highlightedRoleUuid;
        nfcStatus = name != null ? 'Tag scanned: $name' : 'Tag scanned: $tagId';
      });
    });
  }

  void _triggerMockScan(String tagId) {
    widget.nfcService.triggerMockScan(tagId);
  }

  Future<void> _onContinue() async {
    if (_highlightedRoleUuid == null) return;

    final sessionUuid = widget.gameState.sessionUuid;
    final userKey = widget.gameState.localApiPlayer?.accessToken;

    if (sessionUuid == null || userKey == null) {
      setState(() => _joinError = 'Session or player info missing');
      return;
    }

    // Check if the role is already claimed by someone else
    if (_claimedRoleUuids.contains(_highlightedRoleUuid)) {
      setState(() =>
          _joinError = 'This role has already been claimed by another player');
      return;
    }

    // If already joined, just proceed to next screen
    if (_hasJoined) {
      print('✅ Already joined with role $_joinedRoleUuid, proceeding...');
      if (mounted) {
        widget.onCharacterSelected();
      }
      return;
    }

    setState(() {
      _joiningSession = true;
      _joinError = null;
    });

    try {
      await widget.sessionFlow.claimRoleForLocalPlayer(
        gameState: widget.gameState,
        roleUuid: _highlightedRoleUuid!,
      );
      await _refreshSessionPlayers();

      // Success - mark as joined and proceed to next screen
      if (mounted) {
        setState(() {
          _hasJoined = true;
          _joinedRoleUuid = _highlightedRoleUuid;
          _joiningSession = false;
        });
        widget.onCharacterSelected();
      }
    } catch (e) {
      await _refreshSessionPlayers();
      setState(() {
        _joinError = 'Failed to join session: $e';
        _joiningSession = false;
      });
    }
  }

  /// Get image path for a role name
  String? _getRoleImagePath(String roleName) {
    final lower = roleName.toLowerCase();
    if (lower == 'controller') return CharacterClass.controller.imagePath;
    if (lower == 'engineer') return CharacterClass.engineer.imagePath;
    if (lower == 'striker') return CharacterClass.striker.imagePath;
    if (lower == 'vanguard') return CharacterClass.vanguard.imagePath;
    return null;
  }

  /// Map piece color/characterClass to role name
  String? _getPieceColorToRoleName(String characterClass) {
    final lower = characterClass.toLowerCase();
    // Map piece colors to role names
    switch (lower) {
      case 'red':
        return 'Vanguard';
      case 'purple':
        return 'Controller';
      case 'blue':
        return 'Engineer';
      case 'white':
        return 'Striker';
      default:
        return null;
    }
  }

  /// Quick dev shortcut - select vanguard if available
  void _quickDevVanguard() {
    try {
      print('🎯 Quick Dev button pressed');
      print(
        '   Available roles: ${_availableRoles.map((r) => r.name).toList()}',
      );
      print('   Available roles count: ${_availableRoles.length}');

      // Find the vanguard role after backend-to-frontend mapping
      final frontendRoleMap = _buildFrontendRoleMap(_availableRoles);
      final vanguardRole = frontendRoleMap['Vanguard'];

      if (vanguardRole == null) {
        print('❌ Vanguard role not found in available roles');
        setState(() => _joinError = 'Vanguard role not found');
        return;
      }

      print(
        '✅ Found vanguard role: ${vanguardRole.name} (${vanguardRole.uuid})',
      );

      // Check if vanguard is already claimed
      if (_claimedRoleUuids.contains(vanguardRole.uuid)) {
        print('❌ Vanguard is already taken');
        setState(() => _joinError = 'Vanguard is already taken');
        return;
      }

      print('✅ Vanguard is available');

      // Use the red/vanguard NFC tag ID
      const vanguardNfcTagId = '81:2A:C8:6F:42:BA:04';
      print('🎯 Triggering mock scan with tag: $vanguardNfcTagId');
      _triggerMockScan(vanguardNfcTagId);
      print('🎯 Mock scan triggered');
    } catch (e) {
      print('❌ Error in _quickDevVanguard: $e');
      setState(() => _joinError = 'Error selecting character: $e');
    }
  }

  @override
  void dispose() {
    _sessionPlayersRefreshTimer?.cancel();
    widget.nfcService.stopScanning();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frontendRoleMap = _buildFrontendRoleMap(_availableRoles);
    final selectedRoleClaimed = _highlightedRoleUuid != null &&
        widget.gameState.sessionPlayers.any(
          (sessionPlayer) => sessionPlayer.role == _highlightedRoleUuid,
        );
    final canContinue = _hasJoined ||
        (_highlightedRoleUuid != null && !selectedRoleClaimed && !_joiningSession);

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: TokenAndBoardAppBar(onBackPressed: widget.onBack),
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  _hasJoined
                      ? Icons.lock_rounded
                      : (nfcAvailable ? Icons.nfc : Icons.nfc_outlined),
                  size: 64,
                  color: _hasJoined
                      ? Colors.amber
                      : (nfcAvailable ? Colors.green : Colors.red),
                ),
                const SizedBox(height: 16),
                Text(
                  _hasJoined ? 'Character Locked' : 'Select Your Character',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: _hasJoined ? Colors.amber : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _hasJoined
                      ? 'Character selection is locked. Click Continue to proceed.'
                      : nfcStatus,
                  style: TextStyle(
                    color: _hasJoined ? Colors.amber.shade200 : Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Available Roles
          if (_availableRoles.isNotEmpty ||
              _loadingRoles ||
              _rolesError != null)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                color: const Color(0xFF242424),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.assignment_ind_rounded,
                          color: Colors.blue.shade300,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Available Roles',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_loadingRoles)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: SizedBox(
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (_rolesError != null)
                      Text(
                        _rolesError!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                        ),
                      )
                    else
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.9,
                          children: _frontendRoles.map((frontendRoleName) {
                            final role = frontendRoleMap[frontendRoleName];
                            final isAvailableInBackend = role != null;
                            final isClaimed = role != null &&
                                widget.gameState.sessionPlayers.any(
                                  (sessionPlayer) =>
                                      sessionPlayer.role == role.uuid,
                                );
                            final isScanned = role != null &&
                                _highlightedRoleUuid == role.uuid;

                            final occupiedBy = role == null
                                ? null
                                : widget.gameState.sessionPlayers
                                    .where(
                                      (sessionPlayer) =>
                                          sessionPlayer.role == role.uuid,
                                    )
                                    .length;

                            // Determine colors based on state
                            late Color backgroundColor;
                            late Color borderColor;
                            late Color textColor;
                            late Color iconColor;

                            if (!isAvailableInBackend) {
                              backgroundColor = Colors.grey.shade900
                                  .withOpacity(0.45);
                              borderColor = Colors.grey.shade700;
                              textColor = Colors.grey.shade400;
                              iconColor = Colors.grey.shade500;
                            } else if (isScanned) {
                              // Scanned/claimed state
                              backgroundColor =
                                  Colors.yellow.shade900.withOpacity(0.5);
                              borderColor = Colors.yellow.shade500;
                              textColor = Colors.yellow.shade100;
                              iconColor = Colors.yellow.shade300;
                            } else if (isClaimed) {
                              // Claimed state
                              backgroundColor = Colors.red.shade900.withOpacity(
                                0.4,
                              );
                              borderColor = Colors.red.shade700;
                              textColor = Colors.red.shade300;
                              iconColor = Colors.red.shade300;
                            } else {
                              // Available state
                              backgroundColor =
                                  Colors.green.shade900.withOpacity(0.4);
                              borderColor = Colors.green.shade700;
                              textColor = Colors.green.shade300;
                              iconColor = Colors.green.shade300;
                            }

                            return Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: borderColor,
                                  width: isScanned ? 2 : 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Role image
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: _getRoleImagePath(
                                                  frontendRoleName,
                                                ) !=
                                                null
                                            ? Image.asset(
                                                _getRoleImagePath(
                                                  frontendRoleName,
                                                )!,
                                                fit: BoxFit.cover,
                                              )
                                            : Icon(
                                                Icons.person,
                                                size: 40,
                                                color: iconColor,
                                              ),
                                      ),
                                    ),
                                  ),
                                  // Role name
                                  Text(
                                    frontendRoleName,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  // Status indicator
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isClaimed
                                            ? Icons.lock_rounded
                                            : Icons.lock_open_rounded,
                                        size: 14,
                                        color: iconColor,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        !isAvailableInBackend
                                            ? 'Unavailable'
                                            : (isScanned
                                                ? 'Claimed'
                                                : (isClaimed
                                                    ? 'Taken${occupiedBy != null ? ' ($occupiedBy)' : ''}'
                                                    : 'Free')),
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2d2d2d),
            child: Column(
              children: [
                if (_joinError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _joinError!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    // Quick dev button for fast iteration (only when roles are loaded and not joined)
                    if (kMockNfc && !_hasJoined && !_loadingRoles) ...[
                      ElevatedButton.icon(
                        onPressed: _quickDevVanguard,
                        icon: const Icon(Icons.flash_on),
                        label: const Text('Quick Dev (Vanguard)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                    ElevatedButton.icon(
                      onPressed: canContinue ? _onContinue : null,
                      icon: _joiningSession
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Continue'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            canContinue ? Colors.green : Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Session info footer
          SessionInfoFooter(gameState: widget.gameState),
        ],
      ),
    );
  }
}
