class MathQuestion {
  final String displayText;
  final int correctAnswer;
  final MathSkill skill;
  final DateTime generatedAt;

  const MathQuestion({
    required this.displayText,
    required this.correctAnswer,
    required this.skill,
    required this.generatedAt,
  });
}

enum MathSkill { addition, subtraction, multiplication, division }

extension MathSkillLabel on MathSkill {
  String get label {
    switch (this) {
      case MathSkill.addition:       return 'Addition';
      case MathSkill.subtraction:    return 'Subtraction';
      case MathSkill.multiplication: return 'Multiplication';
      case MathSkill.division:       return 'Division';
    }
  }
  String get emoji {
    switch (this) {
      case MathSkill.addition:       return '➕';
      case MathSkill.subtraction:    return '➖';
      case MathSkill.multiplication: return '✖️';
      case MathSkill.division:       return '➗';
    }
  }
}

enum GameMode {
  mixed,
  additionOnly,
  subtractionOnly,
  multiplicationOnly,
  divisionOnly,
  addSubtract,
  multiplyDivide,
}

extension GameModeLabel on GameMode {
  String get label {
    switch (this) {
      case GameMode.mixed:            return '🔀 Mix All';
      case GameMode.additionOnly:     return '➕ Addition';
      case GameMode.subtractionOnly:  return '➖ Subtraction';
      case GameMode.multiplicationOnly: return '✖️ Multiply';
      case GameMode.divisionOnly:     return '➗ Division';
      case GameMode.addSubtract:      return '➕➖ Add & Sub';
      case GameMode.multiplyDivide:   return '✖️➗ Mul & Div';
    }
  }

  List<MathSkill> get skills {
    switch (this) {
      case GameMode.mixed:            return MathSkill.values;
      case GameMode.additionOnly:     return [MathSkill.addition];
      case GameMode.subtractionOnly:  return [MathSkill.subtraction];
      case GameMode.multiplicationOnly: return [MathSkill.multiplication];
      case GameMode.divisionOnly:     return [MathSkill.division];
      case GameMode.addSubtract:      return [MathSkill.addition, MathSkill.subtraction];
      case GameMode.multiplyDivide:   return [MathSkill.multiplication, MathSkill.division];
    }
  }
}

class GameSession {
  final int playerScore;
  final int aiScore;
  final int sessionStreak;
  final int sessionBestStreak;
  final int sessionCorrect;
  final int sessionAnswered;
  final double ropePosition;
  final MathQuestion? playerQuestion;
  final MathQuestion? aiQuestion;
  final String currentInput;
  final int timeLeft;
  final int questionTimeLeft;
  final bool active;
  final bool paused;
  final int coinsEarned;
  final int starsEarned; // UC-009
  final bool isNewRecord; // UC-009
  final AiState aiState;
  final bool playerAnsweredCorrect;
  final bool playerAnsweredWrong;

  const GameSession({
    this.playerScore = 0,
    this.aiScore = 0,
    this.sessionStreak = 0,
    this.sessionBestStreak = 0,
    this.sessionCorrect = 0,
    this.sessionAnswered = 0,
    this.ropePosition = 0.0,
    this.playerQuestion,
    this.aiQuestion,
    this.currentInput = '',
    this.timeLeft = 90,
    this.questionTimeLeft = 7,
    this.active = false,
    this.paused = false,
    this.coinsEarned = 0,
    this.starsEarned = 0,
    this.isNewRecord = false,
    this.aiState = const AiState(),
    this.playerAnsweredCorrect = false,
    this.playerAnsweredWrong = false,
  });

  GameSession copyWith({
    int? playerScore, int? aiScore, int? sessionStreak, int? sessionBestStreak,
    int? sessionCorrect, int? sessionAnswered, double? ropePosition,
    MathQuestion? playerQuestion, MathQuestion? aiQuestion,
    String? currentInput, int? timeLeft, int? questionTimeLeft,
    bool? active, bool? paused, int? coinsEarned, int? starsEarned, bool? isNewRecord,
    AiState? aiState, bool? playerAnsweredCorrect, bool? playerAnsweredWrong,
  }) => GameSession(
    playerScore: playerScore ?? this.playerScore,
    aiScore: aiScore ?? this.aiScore,
    sessionStreak: sessionStreak ?? this.sessionStreak,
    sessionBestStreak: sessionBestStreak ?? this.sessionBestStreak,
    sessionCorrect: sessionCorrect ?? this.sessionCorrect,
    sessionAnswered: sessionAnswered ?? this.sessionAnswered,
    ropePosition: ropePosition ?? this.ropePosition,
    playerQuestion: playerQuestion ?? this.playerQuestion,
    aiQuestion: aiQuestion ?? this.aiQuestion,
    currentInput: currentInput ?? this.currentInput,
    timeLeft: timeLeft ?? this.timeLeft,
    questionTimeLeft: questionTimeLeft ?? this.questionTimeLeft,
    active: active ?? this.active,
    paused: paused ?? this.paused,
    coinsEarned: coinsEarned ?? this.coinsEarned,
    starsEarned: starsEarned ?? this.starsEarned,
    isNewRecord: isNewRecord ?? this.isNewRecord,
    aiState: aiState ?? this.aiState,
    playerAnsweredCorrect: playerAnsweredCorrect ?? this.playerAnsweredCorrect,
    playerAnsweredWrong: playerAnsweredWrong ?? this.playerAnsweredWrong,
  );

  bool get playerWinningByRope => ropePosition <= -10.0;
  bool get aiWinningByRope     => ropePosition >= 10.0;
  String get accuracy {
    if (sessionAnswered == 0) return '0%';
    return '${(sessionCorrect / sessionAnswered * 100).round()}%';
  }
}

class AiState {
  final AiThinkingStatus status;
  final int? displayedAnswer;
  final bool? wasCorrect;
  final String aiQuestion;

  const AiState({
    this.status = AiThinkingStatus.idle,
    this.displayedAnswer,
    this.wasCorrect,
    this.aiQuestion = '',
  });

  AiState copyWith({AiThinkingStatus? status, int? displayedAnswer,
      bool? wasCorrect, String? aiQuestion}) => AiState(
    status: status ?? this.status,
    displayedAnswer: displayedAnswer ?? this.displayedAnswer,
    wasCorrect: wasCorrect ?? this.wasCorrect,
    aiQuestion: aiQuestion ?? this.aiQuestion,
  );
}

enum AiThinkingStatus { idle, thinking, answered, wrong }
enum MatchOutcome { win, lose, draw }
enum ShopCategory { character, rope }

class ShopItem {
  final String id;
  final String name;
  final String emoji;
  final int price;
  final ShopCategory category;
  final String? description;
  const ShopItem({required this.id, required this.name, required this.emoji,
      required this.price, required this.category, this.description});
}

const List<ShopItem> kCharacters = [
  ShopItem(id: 'hero',      name: 'Hero',       emoji: '🦸', price: 0,    category: ShopCategory.character, description: 'The classic champion'),
  ShopItem(id: 'ninja',     name: 'Ninja',      emoji: '🥷', price: 150,  category: ShopCategory.character, description: 'Silent but deadly'),
  ShopItem(id: 'wizard',    name: 'Wizard',     emoji: '🧙', price: 200,  category: ShopCategory.character, description: 'Master of numbers'),
  ShopItem(id: 'robot',     name: 'Robot',      emoji: '🤖', price: 250,  category: ShopCategory.character, description: 'Precision machine'),
  ShopItem(id: 'alien',     name: 'Alien',      emoji: '👽', price: 300,  category: ShopCategory.character, description: 'From beyond the stars'),
  ShopItem(id: 'astronaut', name: 'Astronaut',  emoji: '👨‍🚀', price: 350, category: ShopCategory.character, description: 'Zero-gravity puller'),
  ShopItem(id: 'knight',    name: 'Knight',     emoji: '🧑‍🦰', price: 400,  category: ShopCategory.character, description: 'Armored champion'),
  ShopItem(id: 'pirate',    name: 'Pirate',     emoji: '🏴‍☠️', price: 450, category: ShopCategory.character, description: 'Sea captain'),
  ShopItem(id: 'vampire',   name: 'Vampire',    emoji: '🧛', price: 500,  category: ShopCategory.character, description: 'Night creature'),
  ShopItem(id: 'dragon',    name: 'Dragon',     emoji: '🐲', price: 600,  category: ShopCategory.character, description: 'Fire breather'),
  ShopItem(id: 'clown',     name: 'Clown',      emoji: '🤡', price: 350,  category: ShopCategory.character, description: 'Surprisingly strong'),
  ShopItem(id: 'dino',      name: 'Dino',       emoji: '🦕', price: 700,  category: ShopCategory.character, description: 'Prehistoric power'),
];

const List<ShopItem> kRopes = [
  ShopItem(id: 'classic',   name: 'Classic',    emoji: '🪢', price: 0,    category: ShopCategory.rope, description: 'Old faithful hemp rope'),
  ShopItem(id: 'fire',      name: 'Fire Rope',  emoji: '🔥', price: 200,  category: ShopCategory.rope, description: 'Burns with determination'),
  ShopItem(id: 'ice',       name: 'Ice Rope',   emoji: '❄️', price: 200,  category: ShopCategory.rope, description: 'Cool under pressure'),
  ShopItem(id: 'gold',      name: 'Gold Rope',  emoji: '✨', price: 350,  category: ShopCategory.rope, description: 'Worth its weight'),
  ShopItem(id: 'rainbow',   name: 'Rainbow',    emoji: '🌈', price: 400,  category: ShopCategory.rope, description: 'Colorful & powerful'),
  ShopItem(id: 'electric',  name: 'Electric',   emoji: '⚡', price: 450,  category: ShopCategory.rope, description: 'Charged with energy'),
  ShopItem(id: 'lava',      name: 'Lava Rope',  emoji: '🌋', price: 500,  category: ShopCategory.rope, description: 'Forged in volcano'),
  ShopItem(id: 'neon',      name: 'Neon Glow',  emoji: '💚', price: 550,  category: ShopCategory.rope, description: 'Glows in the dark'),
  ShopItem(id: 'cosmic',    name: 'Cosmic',     emoji: '🌌', price: 650,  category: ShopCategory.rope, description: 'Made of starlight'),
  ShopItem(id: 'dragon',    name: 'Dragon Tail', emoji: '🐉', price: 800,  category: ShopCategory.rope, description: 'Legendary dragon rope'),
];

class Progress {
  int coins;
  List<String> unlockedItems;
  String selectedCharacter;
  String selectedRope;
  int streakDays;
  DateTime? lastPlayedDate;
  int totalWins;
  int totalGames;
  int totalCorrect;
  int totalAnswered;
  int bestStreak;
  int additionCorrect;
  int subtractionCorrect;
  int multiplicationCorrect;
  int divisionCorrect;
  int totalResponseTimeMs;
  int totalQuestionsAnswered;
  
  // NEW FIELDS FOR DAILY QUESTS AND ADVENTURE STARS
  List<DailyQuest> dailyQuests;
  DateTime? lastQuestDate;
  Map<String, int> adventureStars; // e.g. {'additionOnly_1': 3}

  Progress({
    this.coins = 0,
    this.unlockedItems = const [],
    this.selectedCharacter = 'hero',
    this.selectedRope = 'classic',
    this.streakDays = 0,
    this.lastPlayedDate,
    this.totalWins = 0,
    this.totalGames = 0,
    this.totalCorrect = 0,
    this.totalAnswered = 0,
    this.bestStreak = 0,
    this.additionCorrect = 0,
    this.subtractionCorrect = 0,
    this.multiplicationCorrect = 0,
    this.divisionCorrect = 0,
    this.totalResponseTimeMs = 0,
    this.totalQuestionsAnswered = 0,
    this.dailyQuests = const [],
    this.lastQuestDate,
    this.adventureStars = const {},
  });
}

class Profile {
  String ageGroup;
  bool soundOn;
  bool vibrationOn;
  String language;
  bool onboardingComplete;
  String playerName;
  String countryCode;

  Profile({
    this.ageGroup = 'A',
    this.soundOn = true,
    this.vibrationOn = true,
    this.language = 'en',
    this.onboardingComplete = false,
    this.playerName = 'Player',
    this.countryCode = 'US',
  });
}

class AppSettings {
  bool difficultyLock;
  bool adsEnabled;
  int sessionTimeLimit;
  int matchDuration;
  String gameMode;

  AppSettings({
    this.difficultyLock = false,
    this.adsEnabled = true,
    this.sessionTimeLimit = 0,
    this.matchDuration = 60,
    this.gameMode = 'mixed',
  });

  GameMode get gameModeEnum => GameMode.values.firstWhere(
    (e) => e.name == gameMode,
    orElse: () => GameMode.mixed,
  );
}

class LeaderboardEntry {
  String playerName;
  String countryCode;
  int score;
  double accuracy;
  int brainPower;
  DateTime date;
  bool isCurrentUser; 

  LeaderboardEntry({
    required this.playerName, required this.countryCode, required this.score,
    required this.accuracy, required this.brainPower, required this.date,
    this.isCurrentUser = false,
  });

  Map<String, dynamic> toJson() => {
    'playerName': playerName, 'countryCode': countryCode, 'score': score, 
    'accuracy': accuracy, 'brainPower': brainPower, 'date': date.toIso8601String(),
    'isCurrentUser': isCurrentUser,
  };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
    playerName: j['playerName'] ?? 'Player', countryCode: j['countryCode'] ?? 'US',
    score: j['score'] ?? 0, accuracy: (j['accuracy'] ?? 0.0).toDouble(),
    brainPower: j['brainPower'] ?? j['iqScore'] ?? 100, 
    date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
    isCurrentUser: j['isCurrentUser'] ?? false,
  );
}

class DailyQuest {
  final String id; final String title; final int target;
  int current; final int reward; bool isClaimed;

  DailyQuest({
    required this.id, required this.title, required this.target,
    this.current = 0, required this.reward, this.isClaimed = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'target': target, 'current': current,
    'reward': reward, 'isClaimed': isClaimed,
  };

  factory DailyQuest.fromJson(Map<String, dynamic> json) => DailyQuest(
    id: json['id'], title: json['title'], target: json['target'],
    current: json['current'] ?? 0, reward: json['reward'], isClaimed: json['isClaimed'] ?? false,
  );
}