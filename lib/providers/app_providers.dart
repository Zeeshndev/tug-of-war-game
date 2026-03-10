import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_models.dart';
import '../services/storage_service.dart';
import '../services/question_engine.dart';
import '../services/audio_service.dart';

// ── Match Configuration ──────────────────────────────────────────────────────
final matchConfigProvider = StateProvider<Map<String, dynamic>>((ref) => {
  'isAdventure': false, 
  'level': 0, 
  'isBoss': false
});

// ── Profile ─────────────────────────────────────────────────────────────────
class ProfileNotifier extends StateNotifier<Profile> {
  ProfileNotifier() : super(StorageService.getProfile());

  Profile _copy({String? ag, bool? sound, bool? vib, bool? onboard,
      String? name, String? country}) => Profile(
    ageGroup: ag ?? state.ageGroup, soundOn: sound ?? state.soundOn,
    vibrationOn: vib ?? state.vibrationOn, language: state.language,
    onboardingComplete: onboard ?? state.onboardingComplete,
    playerName: name ?? state.playerName,
    countryCode: country ?? state.countryCode,
  );

  Future<void> setAgeGroup(String g) async {
    final p = _copy(ag: g); await StorageService.saveProfile(p); state = p;
  }
  Future<void> setSound(bool on) async {
    AudioService().soundEnabled = on;
    final p = _copy(sound: on); await StorageService.saveProfile(p); state = p;
    if (!on) AudioService().stopBgm();
  }
  Future<void> setVibration(bool on) async {
    final p = _copy(vib: on); await StorageService.saveProfile(p); state = p;
  }
  Future<void> completeOnboarding() async {
    final p = _copy(onboard: true); await StorageService.saveProfile(p); state = p;
  }
  Future<void> setPlayerName(String name) async {
    final p = _copy(name: name); await StorageService.saveProfile(p); state = p;
  }
  Future<void> setCountry(String code) async {
    final p = _copy(country: code); await StorageService.saveProfile(p); state = p;
  }
}
final profileProvider = StateNotifierProvider<ProfileNotifier, Profile>(
    (_) => ProfileNotifier());

// ── Progress ─────────────────────────────────────────────────────────────────
class ProgressNotifier extends StateNotifier<Progress> {
  ProgressNotifier() : super(StorageService.getProgress());

  Progress _clone() => Progress(
    coins: state.coins, unlockedItems: List.from(state.unlockedItems),
    selectedCharacter: state.selectedCharacter, selectedRope: state.selectedRope,
    streakDays: state.streakDays, lastPlayedDate: state.lastPlayedDate,
    totalWins: state.totalWins, totalGames: state.totalGames,
    totalCorrect: state.totalCorrect, totalAnswered: state.totalAnswered,
    bestStreak: state.bestStreak, additionCorrect: state.additionCorrect,
    subtractionCorrect: state.subtractionCorrect,
    multiplicationCorrect: state.multiplicationCorrect,
    divisionCorrect: state.divisionCorrect,
    totalResponseTimeMs: state.totalResponseTimeMs,
    totalQuestionsAnswered: state.totalQuestionsAnswered,
  );

  Future<void> _save(Progress p) async {
    await StorageService.saveProgress(p); state = p;
  }

  Future<void> recordMatchResult({
    required bool won,
    required int sessionCorrect,
    required int sessionAnswered,
    required int sessionBestStreak,
    required int coinsEarned,
    required Map<MathSkill, int> skillCorrect,
    required int sessionScore,
    required int totalResponseMs,
    required int responsesCount,
  }) async {
    final p = _clone();
    StorageService.updateDailyStreak(p);
    p.totalGames += 1;
    if (won) p.totalWins += 1;
    p.totalCorrect += sessionCorrect;
    p.totalAnswered += sessionAnswered;
    if (sessionBestStreak > p.bestStreak) p.bestStreak = sessionBestStreak;
    p.coins += coinsEarned;
    p.additionCorrect       += skillCorrect[MathSkill.addition] ?? 0;
    p.subtractionCorrect    += skillCorrect[MathSkill.subtraction] ?? 0;
    p.multiplicationCorrect += skillCorrect[MathSkill.multiplication] ?? 0;
    p.divisionCorrect       += skillCorrect[MathSkill.division] ?? 0;
    p.totalResponseTimeMs   += totalResponseMs;
    p.totalQuestionsAnswered += responsesCount;
    await _save(p);
  }

  Future<bool> purchaseItem(ShopItem item) async {
    if (state.coins < item.price || state.unlockedItems.contains(item.id)) return false;
    final p = _clone();
    p.coins -= item.price;
    p.unlockedItems.add(item.id);
    if (item.category == ShopCategory.character) p.selectedCharacter = item.id;
    else p.selectedRope = item.id;
    await _save(p);
    return true;
  }

  Future<void> equipItem(ShopItem item) async {
    if (!state.unlockedItems.contains(item.id)) return;
    final p = _clone();
    if (item.category == ShopCategory.character) p.selectedCharacter = item.id;
    else p.selectedRope = item.id;
    await _save(p);
  }
}
final progressProvider = StateNotifierProvider<ProgressNotifier, Progress>(
    (_) => ProgressNotifier());

// ── Settings ─────────────────────────────────────────────────────────────────
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(StorageService.getSettings());

  AppSettings _clone() => AppSettings(
    difficultyLock: state.difficultyLock, adsEnabled: state.adsEnabled,
    sessionTimeLimit: state.sessionTimeLimit, matchDuration: state.matchDuration,
    gameMode: state.gameMode,
  );

  Future<void> _save(AppSettings s) async {
    await StorageService.saveSettings(s); state = s;
  }
  Future<void> setMatchDuration(int v) async {
    final s = _clone()..matchDuration = v; await _save(s);
  }
  Future<void> setGameMode(GameMode m) async {
    final s = _clone()..gameMode = m.name; await _save(s);
  }
  Future<void> toggleDifficultyLock() async {
    final s = _clone()..difficultyLock = !state.difficultyLock; await _save(s);
  }
  Future<void> setTimeLimit(int v) async {
    final s = _clone()..sessionTimeLimit = v; await _save(s);
  }
  Future<void> toggleAds() async {
    final s = _clone()..adsEnabled = !state.adsEnabled; 
    await _save(s);
  }
}
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
    (_) => SettingsNotifier());

// ── Leaderboard ──────────────────────────────────────────────────────────────
class LeaderboardNotifier extends StateNotifier<List<LeaderboardEntry>> {
  LeaderboardNotifier() : super(StorageService.getLeaderboard());

  Future<void> addEntry(LeaderboardEntry entry) async {
    await StorageService.addLeaderboardEntry(entry);
    state = StorageService.getLeaderboard();
  }
  void refresh() {
    state = StorageService.getLeaderboard();
  }
}
final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, List<LeaderboardEntry>>((_) => LeaderboardNotifier());

// ── Brain Power calculator ───────────────────────────────
int calculateBrainPower({
  required int correct, required int answered, required int bestStreak,
  required int matchDuration, required int totalResponseMs, required int responsesCount,
}) {
  if (answered == 0) return 85;
  final acc = correct / answered;
  final avgSec = responsesCount == 0 ? 7.0 : totalResponseMs / responsesCount / 1000.0;
  final speedScore = (1.0 - ((avgSec - 1.0) / 6.0).clamp(0.0, 1.0));
  final streakScore = (bestStreak / max(1, answered)).clamp(0.0, 1.0);
  final composite = acc * 0.45 + speedScore * 0.40 + streakScore * 0.15;
  
  final power = (80 + composite * 80).round();
  return power.clamp(80, 160);
}

// ── Game ─────────────────────────────────────────────────────────────────────
class GameNotifier extends StateNotifier<GameSession> {
  final Ref _ref;
  Timer? _matchTimer, _questionTimer, _aiTimer;
  final Random _rng = Random();
  final Map<MathSkill, int> _skillCorrect = {};
  int _sessionResponseMs = 0;
  int _sessionResponseCount = 0;
  DateTime? _questionStartTime;

  GameNotifier(this._ref) : super(const GameSession());

  String   get _age  => _ref.read(profileProvider).ageGroup;
  int      get _dur  => _ref.read(settingsProvider).matchDuration;
  GameMode get _mode => _ref.read(settingsProvider).gameModeEnum;

  void _evaluateMusic() {
    if (!state.active || state.paused) return;
    
    // Boss music overrides dynamic pulling music
    final isBoss = _ref.read(matchConfigProvider)['isBoss'] == true;
    if (isBoss) {
      AudioService().setBgmState(BgmState.boss);
      return;
    }

    if (state.ropePosition <= -4.0) {
      AudioService().setBgmState(BgmState.winning);
    } else if (state.ropePosition >= 4.0) {
      AudioService().setBgmState(BgmState.losing);
    } else {
      AudioService().setBgmState(BgmState.normal);
    }
  }

  void startMatch() {
    _matchTimer?.cancel(); _questionTimer?.cancel(); _aiTimer?.cancel();
    _skillCorrect.clear();
    _sessionResponseMs = 0;
    _sessionResponseCount = 0;
    final pQ = QuestionEngine.generate(_age, mode: _mode);
    final aQ = QuestionEngine.generate(_age, mode: _mode);
    state = GameSession(
      timeLeft: _dur, questionTimeLeft: 7, active: true,
      playerQuestion: pQ, aiQuestion: aQ,
      aiState: AiState(status: AiThinkingStatus.thinking, aiQuestion: aQ.displayText),
    );
    _questionStartTime = DateTime.now();
    _startMatchTimer();
    _startQuestionTimer();
    _scheduleAI();
    
    // TRIGGER EPIC BOSS MUSIC IF APPLICABLE
    final isBoss = _ref.read(matchConfigProvider)['isBoss'] == true;
    AudioService().setBgmState(isBoss ? BgmState.boss : BgmState.normal);
  }

  void _startMatchTimer() {
    _matchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.active || state.paused) return;
      final t = state.timeLeft - 1;
      if (t <= 0) {
        state = state.copyWith(timeLeft: 0);
        _endMatch(_R.timeout);
      } else {
        state = state.copyWith(timeLeft: t);
      }
    });
  }

  void _startQuestionTimer() {
    _questionTimer?.cancel();
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.active || state.paused) return;
      final qt = state.questionTimeLeft - 1;
      if (qt <= 0) {
        _questionTimer?.cancel();
        _recordResponseTime(timedOut: true);
        state = state.copyWith(
          questionTimeLeft: 0,
          sessionAnswered: state.sessionAnswered + 1,
          sessionStreak: 0,
          ropePosition: min(10.0, state.ropePosition + 0.3),
          currentInput: '',
        );
        _evaluateMusic();
        Future.delayed(const Duration(milliseconds: 400), _nextPlayerQuestion);
      } else {
        state = state.copyWith(questionTimeLeft: qt);
      }
    });
  }

  void _resetQuestionTimer() {
    _questionTimer?.cancel();
    state = state.copyWith(questionTimeLeft: 7);
    _questionStartTime = DateTime.now();
    _startQuestionTimer();
  }

  void _recordResponseTime({bool timedOut = false}) {
    final elapsed = timedOut
        ? 7000
        : (_questionStartTime != null
            ? DateTime.now().difference(_questionStartTime!).inMilliseconds
            : 7000);
    _sessionResponseMs += elapsed.clamp(0, 7000);
    _sessionResponseCount++;
  }

  void _nextPlayerQuestion() {
    if (!state.active) return;
    final q = QuestionEngine.generate(_age, mode: _mode);
    state = state.copyWith(
      playerQuestion: q, currentInput: '',
      playerAnsweredCorrect: false, playerAnsweredWrong: false,
    );
    _resetQuestionTimer();
  }

  void _nextAiQuestion() {
    final q = QuestionEngine.generate(_age, mode: _mode);
    state = state.copyWith(
      aiQuestion: q,
      aiState: AiState(status: AiThinkingStatus.thinking, aiQuestion: q.displayText),
    );
    _scheduleAI();
  }

  void appendDigit(String d) {
    if (!state.active || state.paused || state.currentInput.length >= 5) return;
    state = state.copyWith(currentInput: state.currentInput + d);
    AudioService().playKey();
  }

  void deleteDigit() {
    if (!state.active || state.paused || state.currentInput.isEmpty) return;
    state = state.copyWith(
        currentInput: state.currentInput.substring(0, state.currentInput.length - 1));
  }

  void submitAnswer() {
    if (!state.active || state.paused || state.currentInput.isEmpty) return;
    final q = state.playerQuestion; if (q == null) return;
    final ok = QuestionEngine.validate(state.currentInput, q.correctAnswer);
    if (ok) _playerCorrect(q); else _playerWrong();
  }

  void _playerCorrect(MathQuestion q) {
    _questionTimer?.cancel();
    _recordResponseTime();
    
    final streak = state.sessionStreak + 1;
    final best   = max(streak, state.sessionBestStreak);
    
    // COMBO MULTIPLIER LOGIC
    final pull = 1.5 + (streak >= 10 ? 1.5 : (streak >= 5 ? 1.0 : (streak >= 3 ? 0.5 : 0.0)));
    final rope = max(-10.0, state.ropePosition - pull);
    
    int coins = 2;
    if (streak == 3) coins += 2;
    if (streak == 5) coins += 5;
    if (streak == 10) coins += 10;

    _skillCorrect[q.skill] = (_skillCorrect[q.skill] ?? 0) + 1;
    
    state = state.copyWith(
      playerScore: state.playerScore + 1,
      sessionStreak: streak, sessionBestStreak: best,
      sessionCorrect: state.sessionCorrect + 1,
      sessionAnswered: state.sessionAnswered + 1,
      ropePosition: rope, coinsEarned: state.coinsEarned + coins,
      currentInput: '', playerAnsweredCorrect: true, playerAnsweredWrong: false,
    );
    
    AudioService().playCorrect();
    _evaluateMusic();
    
    if (state.playerWinningByRope) { _endMatch(_R.ropePlayer); return; }
    Future.delayed(const Duration(milliseconds: 400), _nextPlayerQuestion);
  }

  void _playerWrong() {
    _recordResponseTime();
    state = state.copyWith(
      sessionStreak: 0, sessionAnswered: state.sessionAnswered + 1,
      ropePosition: min(10.0, state.ropePosition + 0.3),
      currentInput: '', playerAnsweredCorrect: false, playerAnsweredWrong: true,
    );
    AudioService().playWrong();
    _evaluateMusic();
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (state.active) state = state.copyWith(playerAnsweredWrong: false);
    });
  }

  void _scheduleAI() {
    _aiTimer?.cancel();
    if (!state.active || state.paused) return;
    
    int minMs = _age == 'A' ? 2000 : 1200;
    int maxMs = _age == 'A' ? 5000 : 3500;
    double acc = _age == 'A' ? 0.70 : 0.80;

    // THE BOSS IS FASTER AND SMARTER
    final isBoss = _ref.read(matchConfigProvider)['isBoss'] == true;
    if (isBoss) {
      minMs = (minMs * 0.6).round(); // 40% Faster reaction
      maxMs = (maxMs * 0.6).round();
      acc = min(0.95, acc + 0.15);   // 15% More accurate
    }

    _aiTimer = Timer(
      Duration(milliseconds: minMs + _rng.nextInt(maxMs - minMs)), () {
      if (!state.active || state.paused) return;
      final q = state.aiQuestion; if (q == null) return;
      final ok  = _rng.nextDouble() < acc;
      final ans = ok ? q.correctAnswer : QuestionEngine.generateWrongAnswer(q.correctAnswer);
      if (ok) _aiCorrect(ans, q); else _aiWrong(ans);
    });
  }

  void _aiCorrect(int ans, MathQuestion q) {
    final rope = min(10.0, state.ropePosition + 1.0 + _rng.nextDouble() * 0.5);
    state = state.copyWith(
      aiScore: state.aiScore + 1, ropePosition: rope,
      aiState: AiState(status: AiThinkingStatus.answered, displayedAnswer: ans,
          wasCorrect: true, aiQuestion: q.displayText),
    );
    AudioService().playAiCorrect();
    _evaluateMusic();
    
    if (state.aiWinningByRope) { _endMatch(_R.ropeAi); return; }
    Future.delayed(const Duration(milliseconds: 800), _nextAiQuestion);
  }

  void _aiWrong(int ans) {
    state = state.copyWith(aiState: AiState(
        status: AiThinkingStatus.wrong, displayedAnswer: ans,
        wasCorrect: false, aiQuestion: state.aiQuestion?.displayText ?? ''));
    AudioService().playAiWrong();
    _aiTimer = Timer(const Duration(milliseconds: 1500), () {
      if (state.active && !state.paused) {
        state = state.copyWith(aiState: AiState(
            status: AiThinkingStatus.thinking,
            aiQuestion: state.aiQuestion?.displayText ?? ''));
        _scheduleAI();
      }
    });
  }

  void pause() {
    _aiTimer?.cancel(); _questionTimer?.cancel();
    state = state.copyWith(paused: true);
    AudioService().pauseTick();
  }

  void resume() {
    state = state.copyWith(paused: false);
    _startQuestionTimer(); _scheduleAI();
    AudioService().resumeTick();
  }

  void forceEnd() {
    _matchTimer?.cancel(); _questionTimer?.cancel(); _aiTimer?.cancel();
    AudioService().stopBgm();
    state = state.copyWith(active: false);
  }

  void _endMatch(_R reason) {
    if (!state.active) return;
    _matchTimer?.cancel(); _questionTimer?.cancel(); _aiTimer?.cancel();

    MatchOutcome out;
    if (reason == _R.ropePlayer)      out = MatchOutcome.win;
    else if (reason == _R.ropeAi)     out = MatchOutcome.lose;
    else {
      out = state.playerScore > state.aiScore ? MatchOutcome.win
          : state.aiScore > state.playerScore ? MatchOutcome.lose
          : MatchOutcome.draw;
    }

    // MASSIVE COIN PAYOUT FOR BEATING BOSSES
    final isBoss = _ref.read(matchConfigProvider)['isBoss'] == true;
    final bonus = out == MatchOutcome.win ? (isBoss ? 50 : 15) : out == MatchOutcome.draw ? 5 : 0;
    
    if (out == MatchOutcome.win) {
      AudioService().playWin();
    } else if (out == MatchOutcome.lose) {
      AudioService().playLose();
    } else {
      AudioService().stopBgm();
    }

    final coins = state.coinsEarned + bonus;
    
    final power = calculateBrainPower(
      correct: state.sessionCorrect, answered: state.sessionAnswered,
      bestStreak: state.sessionBestStreak, matchDuration: _dur,
      totalResponseMs: _sessionResponseMs, responsesCount: _sessionResponseCount,
    );

    state = state.copyWith(active: false, coinsEarned: coins);
    final profile = _ref.read(profileProvider);

    _ref.read(progressProvider.notifier).recordMatchResult(
      won: out == MatchOutcome.win, sessionCorrect: state.sessionCorrect,
      sessionAnswered: state.sessionAnswered, sessionBestStreak: state.sessionBestStreak,
      coinsEarned: coins, skillCorrect: Map.from(_skillCorrect),
      sessionScore: state.playerScore, totalResponseMs: _sessionResponseMs,
      responsesCount: _sessionResponseCount,
    );

    _ref.read(leaderboardProvider.notifier).addEntry(LeaderboardEntry(
      playerName: profile.playerName, countryCode: profile.countryCode,
      score: state.playerScore,
      accuracy: state.sessionAnswered == 0 ? 0 : state.sessionCorrect / state.sessionAnswered,
      brainPower: power, date: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _matchTimer?.cancel(); _questionTimer?.cancel(); _aiTimer?.cancel();
    AudioService().stopBgm();
    super.dispose();
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameSession>(
    (ref) => GameNotifier(ref));
enum _R { ropePlayer, ropeAi, timeout }