import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../models/game_models.dart';







class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _p => _prefs!;

  // ── Profile ─────────────────────────────────────────────
  static Profile getProfile() {
    final raw = _p.getString('profile');
    if (raw == null) return Profile();
    try {
      final j = jsonDecode(raw);
      return Profile(
        ageGroup: j['ageGroup'] ?? 'A', soundOn: j['soundOn'] ?? true, vibrationOn: j['vibrationOn'] ?? true,
        language: j['language'] ?? 'en', onboardingComplete: j['onboardingComplete'] ?? false,
        playerName: j['playerName'] ?? 'Player', countryCode: j['countryCode'] ?? 'US',
      );
    } catch (_) { return Profile(); }
  }

  static Future<void> saveProfile(Profile p) async =>
      _p.setString('profile', jsonEncode({
        'ageGroup': p.ageGroup, 'soundOn': p.soundOn, 'vibrationOn': p.vibrationOn,
        'language': p.language, 'onboardingComplete': p.onboardingComplete,
        'playerName': p.playerName, 'countryCode': p.countryCode,
      }));

  // ── Progress ────────────────────────────────────────────
  static Progress getProgress() {
    final raw = _p.getString('progress');
    if (raw == null) return Progress();
    try {
      final j = jsonDecode(raw);
      List<DailyQuest> quests = [];
      if (j['dailyQuests'] != null) {
        quests = (j['dailyQuests'] as List).map((q) => DailyQuest.fromJson(q)).toList();
      }
      return Progress(
        coins: j['coins'] ?? 0, unlockedItems: List<String>.from(j['unlockedItems'] ?? ['hero', 'classic']),
        selectedCharacter: j['selectedCharacter'] ?? 'hero', selectedRope: j['selectedRope'] ?? 'classic',
        streakDays: j['streakDays'] ?? 0, lastPlayedDate: j['lastPlayedDate'] != null ? DateTime.tryParse(j['lastPlayedDate']) : null,
        totalWins: j['totalWins'] ?? 0, totalGames: j['totalGames'] ?? 0,
        totalCorrect: j['totalCorrect'] ?? 0, totalAnswered: j['totalAnswered'] ?? 0, bestStreak: j['bestStreak'] ?? 0,
        additionCorrect: j['additionCorrect'] ?? 0, subtractionCorrect: j['subtractionCorrect'] ?? 0,
        multiplicationCorrect: j['multiplicationCorrect'] ?? 0, divisionCorrect: j['divisionCorrect'] ?? 0,
        totalResponseTimeMs: j['totalResponseTimeMs'] ?? 0, totalQuestionsAnswered: j['totalQuestionsAnswered'] ?? 0,
        dailyQuests: quests, lastQuestDate: j['lastQuestDate'] != null ? DateTime.tryParse(j['lastQuestDate']) : null,
      );
    } catch (_) { return Progress(); }
  }

  static Future<void> saveProgress(Progress p) async =>
      _p.setString('progress', jsonEncode({
        'coins': p.coins, 'unlockedItems': p.unlockedItems,
        'selectedCharacter': p.selectedCharacter, 'selectedRope': p.selectedRope,
        'streakDays': p.streakDays, 'lastPlayedDate': p.lastPlayedDate?.toIso8601String(),
        'totalWins': p.totalWins, 'totalGames': p.totalGames, 'totalCorrect': p.totalCorrect, 'totalAnswered': p.totalAnswered,
        'bestStreak': p.bestStreak, 'additionCorrect': p.additionCorrect, 'subtractionCorrect': p.subtractionCorrect,
        'multiplicationCorrect': p.multiplicationCorrect, 'divisionCorrect': p.divisionCorrect,
        'totalResponseTimeMs': p.totalResponseTimeMs, 'totalQuestionsAnswered': p.totalQuestionsAnswered,
        'dailyQuests': p.dailyQuests.map((q) => q.toJson()).toList(), 'lastQuestDate': p.lastQuestDate?.toIso8601String(),
      }));

  // ── Settings ────────────────────────────────────────────
  static AppSettings getSettings() {
    final raw = _p.getString('settings');
    if (raw == null) return AppSettings();
    try {
      final j = jsonDecode(raw);
      return AppSettings(
        difficultyLock: j['difficultyLock'] ?? false, adsEnabled: j['adsEnabled'] ?? true,
        sessionTimeLimit: j['sessionTimeLimit'] ?? 0, matchDuration: j['matchDuration'] ?? 90, gameMode: j['gameMode'] ?? 'mixed',
      );
    } catch (_) { return AppSettings(); }
  }

  static Future<void> saveSettings(AppSettings s) async =>
      _p.setString('settings', jsonEncode({
        'difficultyLock': s.difficultyLock, 'adsEnabled': s.adsEnabled,
        'sessionTimeLimit': s.sessionTimeLimit, 'matchDuration': s.matchDuration, 'gameMode': s.gameMode,
      }));

  // ── Dynamic Leaderboard Engine ──────────────────────────
  static List<LeaderboardEntry> getLeaderboard() {
    final raw = _p.getString('leaderboard');
    List<LeaderboardEntry> board = [];
    
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        board = list.map((j) => LeaderboardEntry.fromJson(j)).toList();
      } catch (_) {}
    }

    // FORCE 200 ENTRIES: Top up if we have less than 200 players
    if (board.length < 200) {
      int missing = 200 - board.length;
      board.addAll(_generateBots(missing));
      _saveLeaderboard(board);
    }

    // SIMULATE TIME PASSING EVERY 2 HOURS
    final lastSimStr = _p.getString('last_bot_sim');
    final now = DateTime.now();
    if (lastSimStr != null) {
      final lastSim = DateTime.tryParse(lastSimStr) ?? now;
      final hoursPassed = now.difference(lastSim).inHours;
      
      if (hoursPassed >= 2) {
        final rng = Random();
        final cycles = hoursPassed ~/ 2; 
        
        bool ranksChanged = false;
        for (var entry in board) {
          if (!entry.isCurrentUser) {
            // Give 40% of bots a sudden surge in points so ranks shuffle wildly
            if (rng.nextDouble() > 0.6) {
              entry.brainPower += rng.nextInt(6 * cycles) + 2;
              entry.score += rng.nextInt(3 * cycles) + 1;
              ranksChanged = true;
            }
          }
        }
        
        _p.setString('last_bot_sim', now.toIso8601String());
        if (ranksChanged) {
          board.sort((a, b) => b.brainPower.compareTo(a.brainPower));
          _saveLeaderboard(board);
        }
      }
    } else {
      _p.setString('last_bot_sim', now.toIso8601String());
    }

    board.sort((a, b) => b.brainPower.compareTo(a.brainPower));
    return board;
  }

  static Future<void> addLeaderboardEntry(LeaderboardEntry entry) async {
    final board = getLeaderboard();
    
    // De-duplicate the current user
    board.removeWhere((e) => e.isCurrentUser);
    board.add(entry);
    board.sort((a, b) => b.brainPower.compareTo(a.brainPower));
    
    // Ensure we keep exactly 200, but NEVER delete the current user
    var trimmed = board.take(200).toList();
    if (!trimmed.any((e) => e.isCurrentUser)) {
      trimmed.removeLast();
      trimmed.add(entry);
      trimmed.sort((a, b) => b.brainPower.compareTo(a.brainPower));
    }
    
    await _saveLeaderboard(trimmed);
  }

  static Future<void> _saveLeaderboard(List<LeaderboardEntry> board) async {
    await _p.setString('leaderboard', jsonEncode(board.map((e) => e.toJson()).toList()));
  }

  static List<LeaderboardEntry> _generateBots(int count) {
    final rng = Random();
    final countries = ['US', 'GB', 'CA', 'AU', 'DE', 'FR', 'IT', 'IN', 'PK', 'CN', 'JP', 'BR', 'ES', 'NL', 'SE', 'CH'];
    final prefixes = ['Math', 'Calc', 'Quick', 'Brain', 'Smart', 'Fast', 'Pro', 'Elite', 'Mega', 'Super', 'Hyper', 'Quantum'];
    final suffixes = ['Wiz', 'King', 'Kid', 'Master', 'Genius', 'Ninja', 'Bot', 'Star', 'Hero', 'Lord', 'Boss', 'Ace'];
    
    List<LeaderboardEntry> bots = [];
    final now = DateTime.now();

    for (int i = 0; i < count; i++) {
      String name = '${prefixes[rng.nextInt(prefixes.length)]}${suffixes[rng.nextInt(suffixes.length)]}${rng.nextInt(99)}';
      String country = countries[rng.nextInt(countries.length)];
      
      int bp = 100 + rng.nextInt(50) - rng.nextInt(20); 
      int score = (bp / 10).round() + rng.nextInt(5);
      double acc = 0.60 + (rng.nextDouble() * 0.35);

      bots.add(LeaderboardEntry(
        playerName: name, countryCode: country, score: score, accuracy: acc,
        brainPower: bp.clamp(80, 180), date: now.subtract(Duration(hours: rng.nextInt(72))), isCurrentUser: false,
      ));
    }
    return bots;
  }

  static bool get isOnboardingComplete => getProfile().onboardingComplete;

  static void updateDailyStreak(Progress progress) {
    final today = DateTime.now();
    final last = progress.lastPlayedDate;
    if (last == null) {
      progress.streakDays = 1;
    } else {
      final diff = DateTime(today.year, today.month, today.day).difference(DateTime(last.year, last.month, last.day)).inDays;
      if (diff == 1) progress.streakDays += 1;
      else if (diff > 1) progress.streakDays = 1;
    }
    progress.lastPlayedDate = today;
  }
}