import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/soma_theme.dart';

// ============ Piece ============
enum PType { pawn, rook, knight, bishop, queen, king }
enum PSide { white, black }

class Piece {
  final PType type;
  final PSide side;
  Piece(this.type, this.side);

  String get symbol {
    const w = {'pawn': '♙', 'rook': '♖', 'knight': '♘', 'bishop': '♗', 'queen': '♕', 'king': '♔'};
    const b = {'pawn': '♟', 'rook': '♜', 'knight': '♞', 'bishop': '♝', 'queen': '♛', 'king': '♚'};
    const m = {
      'pawn': PType.pawn, 'rook': PType.rook, 'knight': PType.knight,
      'bishop': PType.bishop, 'queen': PType.queen, 'king': PType.king,
    };
    final name = m.entries.firstWhere((e) => e.value == type).key;
    return side == PSide.white ? w[name]! : b[name]!;
  }
}

class ChessScreen extends StatefulWidget {
  const ChessScreen({super.key});

  @override
  State<ChessScreen> createState() => _ChessScreenState();
}

class _ChessScreenState extends State<ChessScreen> {
  late List<List<Piece?>> _board;
  int _selectedRow = -1;
  int _selectedCol = -1;
  List<List<int>> _legalMoves = [];
  bool _whiteTurn = true;
  bool _vsAI = true;
  final List<String> _moveList = [];
  String _status = 'Giliran Putih';
  String _result = '';
  final List<List<List<Piece?>>> _history = [];

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    _board = List.generate(8, (_) => List.filled(8, null));
    // Pawns
    for (int c = 0; c < 8; c++) {
      _board[1][c] = Piece(PType.pawn, PSide.black);
      _board[6][c] = Piece(PType.pawn, PSide.white);
    }
    // Back rows
    final order = [PType.rook, PType.knight, PType.bishop, PType.queen, PType.king, PType.bishop, PType.knight, PType.rook];
    for (int c = 0; c < 8; c++) {
      _board[0][c] = Piece(order[c], PSide.black);
      _board[7][c] = Piece(order[c], PSide.white);
    }
    setState(() {
      _selectedRow = -1;
      _selectedCol = -1;
      _legalMoves = [];
      _whiteTurn = true;
      _moveList.clear();
      _status = 'Giliran ${_whiteTurn ? 'Putih' : 'Hitam'}';
      _result = '';
      _history.clear();
    });
  }

  bool _inBounds(int r, int c) => r >= 0 && r < 8 && c >= 0 && c < 8;

  List<List<int>> _getLegalMoves(int r, int c) {
    final p = _board[r][c]!;
    final moves = <List<int>>[];
    final dir = p.side == PSide.white ? -1 : 1;

    bool addIf(int nr, int nc, {bool mustCapture = false, bool noCapture = false}) {
      if (!_inBounds(nr, nc)) return false;
      final t = _board[nr][nc];
      if (noCapture) {
        if (t == null) { moves.add([nr, nc]); return true; }
        return false;
      }
      if (mustCapture) {
        if (t != null && t.side != p.side) moves.add([nr, nc]);
        return false;
      }
      if (t == null) {
        moves.add([nr, nc]);
        return true;
      } else {
        if (t.side != p.side) moves.add([nr, nc]);
        return false;
      }
    }

    switch (p.type) {
      case PType.pawn:
        if (_inBounds(r + dir, c) && _board[r + dir][c] == null) {
          moves.add([r + dir, c]);
          final startRow = p.side == PSide.white ? 6 : 1;
          if (r == startRow && _board[r + 2 * dir][c] == null) {
            moves.add([r + 2 * dir, c]);
          }
        }
        for (final dc in [-1, 1]) {
          final nr = r + dir, nc = c + dc;
          if (_inBounds(nr, nc)) {
            final t = _board[nr][nc];
            if (t != null && t.side != p.side) moves.add([nr, nc]);
          }
        }
      case PType.rook:
        for (final d in [[-1,0],[1,0],[0,-1],[0,1]]) {
          int nr = r + d[0], nc = c + d[1];
          while (_inBounds(nr, nc)) {
            if (!addIf(nr, nc)) break;
            nr += d[0]; nc += d[1];
          }
        }
      case PType.bishop:
        for (final d in [[-1,-1],[-1,1],[1,-1],[1,1]]) {
          int nr = r + d[0], nc = c + d[1];
          while (_inBounds(nr, nc)) {
            if (!addIf(nr, nc)) break;
            nr += d[0]; nc += d[1];
          }
        }
      case PType.queen:
        for (final d in [[-1,0],[1,0],[0,-1],[0,1],[-1,-1],[-1,1],[1,-1],[1,1]]) {
          int nr = r + d[0], nc = c + d[1];
          while (_inBounds(nr, nc)) {
            if (!addIf(nr, nc)) break;
            nr += d[0]; nc += d[1];
          }
        }
      case PType.knight:
        for (final d in [[-2,-1],[-2,1],[-1,-2],[-1,2],[1,-2],[1,2],[2,-1],[2,1]]) {
          addIf(r + d[0], c + d[1]);
        }
      case PType.king:
        for (final d in [[-1,-1],[-1,0],[-1,1],[0,-1],[0,1],[1,-1],[1,0],[1,1]]) {
          addIf(r + d[0], c + d[1]);
        }
    }
    return moves;
  }

  bool _isInCheck(PSide side) {
    int kr = -1, kc = -1;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final p = _board[r][c];
        if (p != null && p.type == PType.king && p.side == side) {
          kr = r; kc = c;
        }
      }
    }
    if (kr == -1) return false;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final p = _board[r][c];
        if (p != null && p.side != side) {
          final m = _getLegalMoves(r, c);
          for (final mv in m) {
            if (mv[0] == kr && mv[1] == kc) return true;
          }
        }
      }
    }
    return false;
  }

  bool _isCheckmate(PSide side) {
    if (!_isInCheck(side)) return false;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final p = _board[r][c];
        if (p != null && p.side == side) {
          final moves = _getLegalMoves(r, c);
          for (final mv in moves) {
            final saved = _board[mv[0]][mv[1]];
            _board[mv[0]][mv[1]] = p;
            _board[r][c] = null;
            final stillCheck = _isInCheck(side);
            _board[r][c] = p;
            _board[mv[0]][mv[1]] = saved;
            if (!stillCheck) return false;
          }
        }
      }
    }
    return true;
  }

  bool _hasAnyLegalMove(PSide side) {
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final p = _board[r][c];
        if (p != null && p.side == side) {
          final moves = _getLegalMoves(r, c);
          for (final mv in moves) {
            final saved = _board[mv[0]][mv[1]];
            _board[mv[0]][mv[1]] = p;
            _board[r][c] = null;
            final inCheck = _isInCheck(side);
            _board[r][c] = p;
            _board[mv[0]][mv[1]] = saved;
            if (!inCheck) return true;
          }
        }
      }
    }
    return false;
  }

  String _notation(int fromR, int fromC, int toR, int toC, Piece p) {
    const files = ['a','b','c','d','e','f','g','h'];
    final pieceLetter = switch (p.type) {
      PType.pawn => '',
      PType.knight => 'N',
      PType.bishop => 'B',
      PType.rook => 'R',
      PType.queen => 'Q',
      PType.king => 'K',
    };
    final capture = _board[toR][toC] != null ? 'x' : '';
    return '$pieceLetter$capture${files[toC]}${8 - toR}';
  }

  void _onCellTap(int r, int c) {
    if (_result.isNotEmpty) return;
    final p = _board[r][c];
    if (_selectedRow == -1) {
      if (p == null) return;
      final myTurn = (p.side == PSide.white) == _whiteTurn;
      if (!myTurn) return;
      setState(() {
        _selectedRow = r;
        _selectedCol = c;
        _legalMoves = _getLegalMoves(r, c);
      });
    } else {
      final isLegal = _legalMoves.any((m) => m[0] == r && m[1] == c);
      if (isLegal) {
        _makeMove(_selectedRow, _selectedCol, r, c);
      } else if (p != null && ((p.side == PSide.white) == _whiteTurn)) {
        setState(() {
          _selectedRow = r;
          _selectedCol = c;
          _legalMoves = _getLegalMoves(r, c);
        });
      } else {
        setState(() {
          _selectedRow = -1;
          _selectedCol = -1;
          _legalMoves = [];
        });
      }
    }
  }

  void _makeMove(int fromR, int fromC, int toR, int toC) {
    final p = _board[fromR][fromC]!;
    final notation = _notation(fromR, fromC, toR, toC, p);
    _history.add(_board.map((row) => List<Piece?>.from(row)).toList());
    _board[toR][toC] = p;
    _board[fromR][fromC] = null;
    // Auto queen promotion
    if (p.type == PType.pawn && (toR == 0 || toR == 7)) {
      _board[toR][toC] = Piece(PType.queen, p.side);
    }
    setState(() {
      _whiteTurn = !_whiteTurn;
      _moveList.add(notation);
      _selectedRow = -1;
      _selectedCol = -1;
      _legalMoves = [];
      _updateStatus();
    });
    if (_vsAI && _whiteTurn == false && _result.isEmpty) {
      Timer(const Duration(milliseconds: 400), _aiMove);
    }
  }

  void _updateStatus() {
    final side = _whiteTurn ? PSide.white : PSide.black;
    final sideName = _whiteTurn ? 'Putih' : 'Hitam';
    if (_isCheckmate(side)) {
      _status = 'Checkmate!';
      _result = '${_whiteTurn ? 'Hitam' : 'Putih'} Menang';
    } else if (_isInCheck(side)) {
      _status = '$sideName dalam Check!';
    } else if (!_hasAnyLegalMove(side)) {
      _status = 'Stalemate!';
      _result = 'Draw';
    } else {
      _status = 'Giliran $sideName';
    }
  }

  // ============ AI (minimax depth 2) ============
  void _aiMove() {
    final best = _findBestMove(PSide.black, 2);
    if (best != null) {
      _makeMove(best[0], best[1], best[2], best[3]);
    }
  }

  List<int>? _findBestMove(PSide side, int depth) {
    int bestScore = side == PSide.black ? 999999 : -999999;
    List<int>? bestMove;
    final moves = <List<int>>[];
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final p = _board[r][c];
        if (p != null && p.side == side) {
          final m = _getLegalMoves(r, c);
          for (final mv in m) {
            moves.add([r, c, mv[0], mv[1]]);
          }
        }
      }
    }
    for (final m in moves) {
      final saved = _board[m[2]][m[3]];
      final movedP = _board[m[0]][m[1]]!;
      _board[m[2]][m[3]] = movedP;
      _board[m[0]][m[1]] = null;
      final score = _minimax(depth - 1, side == PSide.black ? false : true, -999999, 999999);
      _board[m[0]][m[1]] = movedP;
      _board[m[2]][m[3]] = saved;
      if (side == PSide.black) {
        if (score < bestScore) { bestScore = score; bestMove = m; }
      } else {
        if (score > bestScore) { bestScore = score; bestMove = m; }
      }
    }
    return bestMove;
  }

  int _minimax(int depth, bool maximizing, int alpha, int beta) {
    if (depth == 0) return _evalBoard();
    final side = maximizing ? PSide.white : PSide.black;
    final moves = <List<int>>[];
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final p = _board[r][c];
        if (p != null && p.side == side) {
          final m = _getLegalMoves(r, c);
          for (final mv in m) {
            moves.add([r, c, mv[0], mv[1]]);
          }
        }
      }
    }
    if (moves.isEmpty) return _evalBoard();
    if (maximizing) {
      int best = -999999;
      for (final m in moves) {
        final saved = _board[m[2]][m[3]];
        final movedP = _board[m[0]][m[1]]!;
        _board[m[2]][m[3]] = movedP;
        _board[m[0]][m[1]] = null;
        final v = _minimax(depth - 1, false, alpha, beta);
        _board[m[0]][m[1]] = movedP;
        _board[m[2]][m[3]] = saved;
        best = math.max(best, v);
        alpha = math.max(alpha, v);
        if (beta <= alpha) break;
      }
      return best;
    } else {
      int best = 999999;
      for (final m in moves) {
        final saved = _board[m[2]][m[3]];
        final movedP = _board[m[0]][m[1]]!;
        _board[m[2]][m[3]] = movedP;
        _board[m[0]][m[1]] = null;
        final v = _minimax(depth - 1, true, alpha, beta);
        _board[m[0]][m[1]] = movedP;
        _board[m[2]][m[3]] = saved;
        best = math.min(best, v);
        beta = math.min(beta, v);
        if (beta <= alpha) break;
      }
      return best;
    }
  }

  int _evalBoard() {
    final vals = {PType.pawn: 1, PType.knight: 3, PType.bishop: 3, PType.rook: 5, PType.queen: 9, PType.king: 0};
    int score = 0;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final p = _board[r][c];
        if (p != null) {
          final v = vals[p.type]!;
          score += p.side == PSide.white ? v : -v;
        }
      }
    }
    return score;
  }

  void _undo() {
    if (_history.isEmpty) return;
    final prev = _history.removeLast();
    setState(() {
      _board = prev;
      _whiteTurn = !_whiteTurn;
      if (_moveList.isNotEmpty) _moveList.removeLast();
      _selectedRow = -1;
      _selectedCol = -1;
      _legalMoves = [];
      _result = '';
      _status = 'Giliran ${_whiteTurn ? 'Putih' : 'Hitam'}';
    });
  }

  void _resign() {
    setState(() {
      _result = _whiteTurn ? 'Hitam Menang' : 'Putih Menang';
      _status = 'Resign';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SomaTheme.bgDeep,
      appBar: AppBar(
        title: const Text('Chess', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(onPressed: _newGame, icon: const Icon(Icons.refresh), tooltip: 'New Game'),
          IconButton(onPressed: _undo, icon: const Icon(Icons.undo), tooltip: 'Undo'),
          IconButton(onPressed: _resign, icon: const Icon(Icons.flag), tooltip: 'Resign'),
        ],
      ),
      body: Column(
        children: [
          // Mode selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('vs AI'),
                    selected: _vsAI,
                    selectedColor: SomaTheme.teal,
                    backgroundColor: SomaTheme.bgCard,
                    labelStyle: TextStyle(color: _vsAI ? SomaTheme.white : SomaTheme.textMuted),
                    onSelected: (_) { setState(() => _vsAI = true); _newGame(); },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('vs Human'),
                    selected: !_vsAI,
                    selectedColor: SomaTheme.lavender,
                    backgroundColor: SomaTheme.bgCard,
                    labelStyle: TextStyle(color: !_vsAI ? SomaTheme.bgDeep : SomaTheme.textMuted),
                    onSelected: (_) { setState(() => _vsAI = false); _newGame(); },
                  ),
                ),
              ],
            ),
          ),
          // Board
          Padding(
            padding: const EdgeInsets.all(8),
            child: AspectRatio(
              aspectRatio: 1,
              child: _buildBoard(),
            ),
          ),
          // Status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_status, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _result.isNotEmpty ? SomaTheme.tealBright : SomaTheme.text)),
                if (_result.isNotEmpty)
                  Text(_result, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: SomaTheme.lavender)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Move list
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SomaTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SomaTheme.teal.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.list_alt, color: SomaTheme.tealBright, size: 18),
                      const SizedBox(width: 6),
                      Text('Moves', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SomaTheme.white)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _moveList.isEmpty
                        ? Center(child: Text('Belum ada langkah', style: TextStyle(color: SomaTheme.textMuted, fontSize: 12)))
                        : ListView.builder(
                            itemCount: (_moveList.length / 2).ceil(),
                            itemBuilder: (ctx, i) {
                              final w = i * 2 < _moveList.length ? _moveList[i * 2] : '';
                              final b = i * 2 + 1 < _moveList.length ? _moveList[i * 2 + 1] : '';
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    SizedBox(width: 24, child: Text('${i + 1}.', style: TextStyle(color: SomaTheme.textMuted, fontSize: 12))),
                                    SizedBox(width: 60, child: Text(w, style: TextStyle(color: SomaTheme.text, fontSize: 12))),
                                    SizedBox(width: 60, child: Text(b, style: TextStyle(color: SomaTheme.lavender, fontSize: 12))),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
      itemCount: 64,
      itemBuilder: (ctx, idx) {
        final r = idx ~/ 8;
        final c = idx % 8;
        final dark = (r + c) % 2 == 1;
        final p = _board[r][c];
        final isSelected = _selectedRow == r && _selectedCol == c;
        final isLegal = _legalMoves.any((m) => m[0] == r && m[1] == c);
        Color bg;
        if (isSelected) {
          bg = SomaTheme.tealBright.withOpacity(0.4);
        } else if (isLegal) {
          bg = SomaTheme.teal.withOpacity(0.25);
        } else {
          bg = dark ? const Color(0xFF1a2744) : const Color(0xFF243352);
        }
        return GestureDetector(
          onTap: () => _onCellTap(r, c),
          child: Container(
            color: bg,
            child: Stack(
              children: [
                if (p != null)
                  Center(
                    child: Text(
                      p.symbol,
                      style: TextStyle(
                        fontSize: 32,
                        color: p.side == PSide.white ? SomaTheme.white : const Color(0xFF1e293b),
                        shadows: p.side == PSide.black
                            ? [const Shadow(color: Colors.white54, blurRadius: 2)]
                            : [const Shadow(color: Colors.black54, blurRadius: 2)],
                      ),
                    ),
                  ),
                if (isLegal && p == null)
                  Center(
                    child: Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: SomaTheme.teal.withOpacity(0.6),
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
}