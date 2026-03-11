import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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
        ageGroup: j['ageGroup'] ?? 'A',
        soundOn: j['soundOn'] ?? true,
        vibrationOn: j['vibrationOn'] ?? true,
        language: j['language'] ?? 'en',
        onboardingComplete: j['onboardingComplete'] ?? false,
        playerName: j['playerName'] ?? 'Player',
        countryCode: j['countryCode'] ?? 'US',
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
      
      // Parse Daily Quests with backwards compatibility
      List<DailyQuest> quests = [];
      if (j['dailyQuests'] != null) {
        quests = (j['dailyQuests'] as List).map((q) => DailyQuest.fromJson(q)).toList();
      }

      return Progress(
        coins: j['coins'] ?? 0,
        unlockedItems: List<String>.from(j['unlockedItems'] ?? ['hero', 'classic']),
        selectedCharacter: j['selectedCharacter'] ?? 'hero',
        selectedRope: j['selectedRope'] ?? 'classic',
        streakDays: j['streakDays'] ?? 0,
        lastPlayedDate: j['lastPlayedDate'] != null ? DateTime.tryParse(j['lastPlayedDate']) : null,
        totalWins: j['totalWins'] ?? 0, totalGames: j['totalGames'] ?? 0,
        totalCorrect: j['totalCorrect'] ?? 0, totalAnswered: j['totalAnswered'] ?? 0,
        bestStreak: j['bestStreak'] ?? 0,
        additionCorrect: j['additionCorrect'] ?? 0,
        subtractionCorrect: j['subtractionCorrect'] ?? 0,
        multiplicationCorrect: j['multiplicationCorrect'] ?? 0,
        divisionCorrect: j['divisionCorrect'] ?? 0,
        totalResponseTimeMs: j['totalResponseTimeMs'] ?? 0,
        totalQuestionsAnswered: j['totalQuestionsAnswered'] ?? 0,
        dailyQuests: quests,
        lastQuestDate: j['lastQuestDate'] != null ? DateTime.tryParse(j['lastQuestDate']) : null,
      );
    } catch (_) { return Progress(); }
  }

  static Future<void> saveProgress(Progress p) async =>
      _p.setString('progress', jsonEncode({
        'coins': p.coins, 'unlockedItems': p.unlockedItems,
        'selectedCharacter': p.selectedCharacter, 'selectedRope': p.selectedRope,
        'streakDays': p.streakDays, 'lastPlayedDate': p.lastPlayedDate?.toIso8601String(),
        'totalWins': p.totalWins, 'totalGames': p.totalGames,
        'totalCorrect': p.totalCorrect, 'totalAnswered': p.totalAnswered,
        'bestStreak': p.bestStreak, 'additionCorrect': p.additionCorrect,
        'subtractionCorrect': p.subtractionCorrect, 'multiplicationCorrect': p.multiplicationCorrect,
        'divisionCorrect': p.divisionCorrect,
        'totalResponseTimeMs': p.totalResponseTimeMs,
        'totalQuestionsAnswered': p.totalQuestionsAnswered,
        'dailyQuests': p.dailyQuests.map((q) => q.toJson()).toList(),
        'lastQuestDate': p.lastQuestDate?.toIso8601String(),
      }));

  // ── Settings ────────────────────────────────────────────
  static AppSettings getSettings() {
    final raw = _p.getString('settings');
    if (raw == null) return AppSettings();
    try {
      final j = jsonDecode(raw);
      return AppSettings(
        difficultyLock: j['difficultyLock'] ?? false,
        adsEnabled: j['adsEnabled'] ?? true,
        sessionTimeLimit: j['sessionTimeLimit'] ?? 0,
        matchDuration: j['matchDuration'] ?? 90,
        gameMode: j['gameMode'] ?? 'mixed',
      );
    } catch (_) { return AppSettings(); }
  }

  static Future<void> saveSettings(AppSettings s) async =>
      _p.setString('settings', jsonEncode({
        'difficultyLock': s.difficultyLock, 'adsEnabled': s.adsEnabled,
        'sessionTimeLimit': s.sessionTimeLimit, 'matchDuration': s.matchDuration,
        'gameMode': s.gameMode,
      }));

  // ── Leaderboard ─────────────────────────────────────────
  static List<LeaderboardEntry> getLeaderboard() {
    final raw = _p.getString('leaderboard');
    if (raw == null) return _defaultLeaderboard();
    try {
      final list = jsonDecode(raw) as List;
      return list.map((j) => LeaderboardEntry(
        playerName: j['playerName'] ?? 'Player',
        countryCode: j['countryCode'] ?? 'US',
        score: j['score'] ?? 0,
        accuracy: (j['accuracy'] ?? 0.0).toDouble(),
        brainPower: j['brainPower'] ?? j['iqScore'] ?? 100, 
        date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
      )).toList();
    } catch (_) { return _defaultLeaderboard(); }
  }

  static Future<void> addLeaderboardEntry(LeaderboardEntry entry) async {
    final board = getLeaderboard();
    board.add(entry);
    
    // Sort by Brain Power desc, keep top 100
    board.sort((a, b) => b.brainPower.compareTo(a.brainPower));
    final trimmed = board.take(100).toList();
    
    await _p.setString('leaderboard', jsonEncode(trimmed.map((e) => {
      'playerName': e.playerName, 'countryCode': e.countryCode,
      'score': e.score, 'accuracy': e.accuracy,
      'brainPower': e.brainPower, 'date': e.date.toIso8601String(),
    }).toList()));
  }

  static List<LeaderboardEntry> _defaultLeaderboard() {
    final now = DateTime.now();
    return [
      LeaderboardEntry(playerName: 'MathWiz', countryCode: 'US', score: 18, accuracy: 0.94, brainPower: 142, date: now.subtract(const Duration(days: 1))),
      LeaderboardEntry(playerName: 'QuickCalc', countryCode: 'CN', score: 17, accuracy: 0.91, brainPower: 138, date: now.subtract(const Duration(days: 2))),
      LeaderboardEntry(playerName: 'NumberKing', countryCode: 'IN', score: 16, accuracy: 0.89, brainPower: 135, date: now.subtract(const Duration(days: 3))),
      LeaderboardEntry(playerName: 'BrainStorm', countryCode: 'GB', score: 15, accuracy: 0.87, brainPower: 131, date: now.subtract(const Duration(days: 4))),
      LeaderboardEntry(playerName: 'TugMaster', countryCode: 'PK', score: 14, accuracy: 0.85, brainPower: 128, date: now.subtract(const Duration(days: 5))),
      LeaderboardEntry(playerName: 'AlgebraAce', countryCode: 'DE', score: 14, accuracy: 0.83, brainPower: 126, date: now.subtract(const Duration(days: 6))),
      LeaderboardEntry(playerName: 'SpeedMath', countryCode: 'JP', score: 13, accuracy: 0.81, brainPower: 122, date: now.subtract(const Duration(days: 7))),
      LeaderboardEntry(playerName: 'PullPower', countryCode: 'AU', score: 12, accuracy: 0.78, brainPower: 118, date: now.subtract(const Duration(days: 8))),
      LeaderboardEntry(playerName: 'CalcKid', countryCode: 'CA', score: 11, accuracy: 0.75, brainPower: 114, date: now.subtract(const Duration(days: 9))),
      LeaderboardEntry(playerName: 'RopeRacer', countryCode: 'FR', score: 10, accuracy: 0.72, brainPower: 110, date: now.subtract(const Duration(days: 10))),
    ];
  }

  static bool get isOnboardingComplete => getProfile().onboardingComplete;

  static void updateDailyStreak(Progress progress) {
    final today = DateTime.now();
    final last = progress.lastPlayedDate;
    if (last == null) {
      progress.streakDays = 1;
    } else {
      final diff = DateTime(today.year, today.month, today.day)
          .difference(DateTime(last.year, last.month, last.day)).inDays;
      if (diff == 1) progress.streakDays += 1;
      else if (diff > 1) progress.streakDays = 1;
    }
    progress.lastPlayedDate = today;
  }
}