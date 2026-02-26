import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_state.dart';
import '../services/session_api_service.dart';
import '../services/management_api_service.dart' show ApiPlayer, ApiGame;
import '../widgets/token_and_board_app_bar.dart';

/// Screen for creating a new session or joining an existing one.
///
/// Session operations require a player's `x-user-key` (access token), so the
/// user must first identify which registered player they are.
class SessionSelectionScreen extends StatefulWidget {
  final GameState gameState;
  final SessionApiService sessionApi;
  final VoidCallback onSessionReady;
  final VoidCallback onBack;

  const SessionSelectionScreen({
    super.key,
    required this.gameState,
    required this.sessionApi,
    required this.onSessionReady,
    required this.onBack,
  });

  @override
  State<SessionSelectionScreen> createState() => _SessionSelectionScreenState();
}

class _SessionSelectionScreenState extends State<SessionSelectionScreen> {
  // ── Player selection ──────────────────────────────────────────────────────
  ApiPlayer? _selectedPlayer;

  // ── Create session ────────────────────────────────────────────────────────
  ApiGame? _selectedGame;
  bool _creating = false;
  String? _createdJoinCode;
  String? _createError;

  // ── Join session ──────────────────────────────────────────────────────────
  final _joinCodeController = TextEditingController();
  bool _joining = false;
  String? _joinError;
  String? _joinedCode; // confirmation display

  List<ApiPlayer> get _players => widget.gameState.apiPlayers;

  @override
  void initState() {
    super.initState();
    // Pre-fill game chosen on the scenario selection screen
    _selectedGame = widget.gameState.selectedApiGame;
  }

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool get _hasPlayer => _selectedPlayer != null;

  void _resetCreateState() => setState(() {
    _createdJoinCode = null;
    _createError = null;
  });

  void _resetJoinState() => setState(() {
    _joinError = null;
    _joinedCode = null;
  });

  // ── Create ────────────────────────────────────────────────────────────────

  Future<void> _createSession() async {
    if (_selectedPlayer == null || _selectedGame == null) return;
    setState(() {
      _creating = true;
      _createError = null;
      _createdJoinCode = null;
    });
    try {
      final result = await widget.sessionApi.createSession(
        gameUuid: _selectedGame!.uuid,
        userKey: _selectedPlayer!.accessToken,
      );
      widget.gameState
        ..sessionUuid = result.uuid
        ..sessionId = result.joinCode
        ..localApiPlayer = _selectedPlayer;
      setState(() {
        _createdJoinCode = result.joinCode;
        _creating = false;
      });
    } catch (e) {
      setState(() {
        _createError = e.toString();
        _creating = false;
      });
    }
  }

  void _confirmCreate() => widget.onSessionReady();

  // ── Join ──────────────────────────────────────────────────────────────────

  Future<void> _joinSession() async {
    if (_selectedPlayer == null) return;
    final code = _joinCodeController.text.trim().toUpperCase();
    if (code.length != 8) {
      setState(() => _joinError = 'Enter the full 8-character join code');
      return;
    }
    setState(() {
      _joining = true;
      _joinError = null;
      _joinedCode = null;
    });
    try {
      final detail = await widget.sessionApi.getSessionByJoinCode(code);
      widget.gameState
        ..sessionUuid = detail.uuid
        ..sessionId = detail.joinCode
        ..localApiPlayer = _selectedPlayer;
      setState(() {
        _joinedCode = detail.joinCode;
        _joining = false;
      });
    } catch (e) {
      setState(() {
        _joinError = e.toString();
        _joining = false;
      });
    }
  }

  void _confirmJoin() => widget.onSessionReady();

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: TokenAndBoardAppBar(onBackPressed: widget.onBack),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Title ──────────────────────────────────────────────────
              const Text(
                'Session',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a new session or join an existing one',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // ── Player picker ──────────────────────────────────────────
              _SectionCard(
                icon: Icons.person_outline,
                iconColor: Colors.amber.shade300,
                title: 'You are…',
                subtitle: 'Select your player profile to authenticate.',
                child: _players.isEmpty
                    ? _infoText('No players found. Check your API connection.')
                    : DropdownButtonFormField<ApiPlayer>(
                        value: _selectedPlayer,
                        dropdownColor: const Color(0xFF2d2d2d),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Select player'),
                        items: _players
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.name),
                              ),
                            )
                            .toList(),
                        onChanged: (p) {
                          setState(() {
                            _selectedPlayer = p;
                            _resetCreateState();
                            _resetJoinState();
                          });
                        },
                      ),
              ),

              const SizedBox(height: 20),

              // ── Create session ─────────────────────────────────────────
              _SectionCard(
                icon: Icons.add_circle_outline,
                iconColor: Colors.blue.shade300,
                title: 'Create Session',
                subtitle: 'Start a new game session and share the code.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Game picker
                    widget.gameState.apiGames.isEmpty
                        ? _infoText(
                            'No games found. Check your API connection.',
                          )
                        : DropdownButtonFormField<ApiGame>(
                            value: _selectedGame,
                            dropdownColor: const Color(0xFF2d2d2d),
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Select game'),
                            items: widget.gameState.apiGames
                                .map(
                                  (g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (g) {
                              setState(() {
                                _selectedGame = g;
                                _resetCreateState();
                              });
                            },
                          ),
                    if (_createError != null) ...[
                      const SizedBox(height: 8),
                      _errorText(_createError!),
                    ],
                    if (_createdJoinCode != null) ...[
                      const SizedBox(height: 12),
                      _JoinCodeDisplay(code: _createdJoinCode!),
                      const SizedBox(height: 12),
                      _primaryButton(
                        label: 'Continue',
                        icon: Icons.arrow_forward_rounded,
                        color: Colors.green.shade700,
                        onPressed: _confirmCreate,
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      _primaryButton(
                        label: _creating ? 'Creating…' : 'Create Session',
                        icon: Icons.play_arrow_rounded,
                        color: Colors.blue.shade700,
                        onPressed:
                            (!_hasPlayer || _selectedGame == null || _creating)
                            ? null
                            : _createSession,
                        loading: _creating,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Join session ───────────────────────────────────────────
              _SectionCard(
                icon: Icons.group_add_outlined,
                iconColor: Colors.deepPurple.shade200,
                title: 'Join Session',
                subtitle: 'Enter the 8-character code shared by the host.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _joinCodeController,
                      enabled: _hasPlayer && _joinedCode == null,
                      onChanged: (_) => setState(() => _joinError = null),
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9]'),
                        ),
                        LengthLimitingTextInputFormatter(8),
                      ],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'ABCD1234',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.25),
                          letterSpacing: 4,
                          fontSize: 22,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2d2d2d),
                        errorText: _joinError,
                        errorStyle: const TextStyle(color: Colors.redAccent),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.deepPurple.shade300,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_joinedCode != null) ...[
                      _JoinCodeDisplay(
                        code: _joinedCode!,
                        label: 'Joined session:',
                      ),
                      const SizedBox(height: 12),
                      _primaryButton(
                        label: 'Continue',
                        icon: Icons.arrow_forward_rounded,
                        color: Colors.green.shade700,
                        onPressed: _confirmJoin,
                      ),
                    ] else
                      _primaryButton(
                        label: _joining ? 'Joining…' : 'Join Session',
                        icon: Icons.login_rounded,
                        color: Colors.deepPurple.shade700,
                        onPressed: (!_hasPlayer || _joining)
                            ? null
                            : _joinSession,
                        loading: _joining,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Small helpers ─────────────────────────────────────────────────────────

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
    filled: true,
    fillColor: const Color(0xFF2d2d2d),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.white24, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  Widget _infoText(String msg) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      msg,
      style: TextStyle(color: Colors.amber.shade300, fontSize: 12),
    ),
  );

  Widget _errorText(String msg) =>
      Text(msg, style: const TextStyle(color: Colors.redAccent, fontSize: 12));

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    bool loading = false,
  }) => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: color.withOpacity(0.35),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

// ── Join code display ─────────────────────────────────────────────────────────

class _JoinCodeDisplay extends StatelessWidget {
  final String code;
  final String label;

  const _JoinCodeDisplay({required this.code, this.label = 'Share this code:'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade700, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                code,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.white54, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copied to clipboard')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
