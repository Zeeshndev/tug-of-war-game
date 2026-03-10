import 'package:just_audio/just_audio.dart';

enum BgmState { menu, normal, boss, winning, losing, resultWin, resultLose, stopped }

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  bool soundEnabled = true;

  final AudioPlayer _bgmPlayer = AudioPlayer();
  BgmState _currentBgmState = BgmState.stopped;

  // ── Cloudinary URLs ──────────────────────────────────────────────────────
  final String _urlMenu = 'https://res.cloudinary.com/dxtegwucd/video/upload/v1773104713/default_tkyxgn.mp3';
  final String _urlNormal = 'https://res.cloudinary.com/dxtegwucd/video/upload/v1773104433/bgm_normal_pjhviz.mp3';
  final String _urlWinning = 'https://res.cloudinary.com/dxtegwucd/video/upload/v1773104438/bgm_winning_ykxe0d.mp3';
  final String _urlLosing = 'https://res.cloudinary.com/dxtegwucd/video/upload/v1773104438/bgm_losing_q4p2cx.mp3';
  final String _urlWinSfx = 'https://res.cloudinary.com/dxtegwucd/video/upload/v1773104438/win_ojnrsr.mp3';
  final String _urlLoseSfx = 'https://res.cloudinary.com/dxtegwucd/video/upload/v1773104438/lose_egww5f.mp3';
  // Fast, intense track for the Boss Battles (Currently reusing winning track as a placeholder)
  final String _urlBoss = 'https://res.cloudinary.com/dxtegwucd/video/upload/v1773104438/bgm_winning_ykxe0d.mp3'; 

  // ── Background Music Logic ───────────────────────────────────────────────
  
  Future<void> setBgmState(BgmState newState) async {
    if (!soundEnabled || _currentBgmState == newState) return;
    
    _currentBgmState = newState;
    await _bgmPlayer.stop();

    String url = '';
    switch (newState) {
      case BgmState.menu:
        url = _urlMenu;
        break;
      case BgmState.normal:
        url = _urlNormal;
        break;
      case BgmState.boss:
        url = _urlBoss;
        break;
      case BgmState.winning:
        url = _urlWinning;
        break;
      case BgmState.losing:
        url = _urlLosing;
        break;
      case BgmState.resultWin:
        url = _urlWinSfx;
        break;
      case BgmState.resultLose:
        url = _urlLoseSfx;
        break;
      case BgmState.stopped:
        return;
    }

    try {
      await _bgmPlayer.setUrl(url);
      await _bgmPlayer.setLoopMode(LoopMode.one); 
      _bgmPlayer.play();
    } catch (e) {
      print("Audio URL failed to load: $url"); 
    }
  }

  void stopBgm() {
    _currentBgmState = BgmState.stopped;
    _bgmPlayer.stop();
  }

  // ── Sound Effects Logic ──────────────────────────────────────────────────
  Future<void> _playLocalSfx(String path) async {
    if (!soundEnabled) return;
    try {
      final player = AudioPlayer();
      await player.setAsset(path);
      player.play();
      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          player.dispose();
        }
      });
    } catch (e) {
      print("Local SFX not found: $path");
    }
  }

  void playKey() => _playLocalSfx('assets/audio/key.mp3');
  void playCorrect() => _playLocalSfx('assets/audio/correct.mp3');
  void playWrong() => _playLocalSfx('assets/audio/wrong.mp3');
  void playAiCorrect() => _playLocalSfx('assets/audio/ai_correct.mp3'); 
  void playAiWrong() => _playLocalSfx('assets/audio/ai_wrong.mp3');     
  
  void playWin() => setBgmState(BgmState.resultWin);
  void playLose() => setBgmState(BgmState.resultLose);

  void startTick() => setBgmState(BgmState.normal);
  void pauseTick() => _bgmPlayer.pause();
  void resumeTick() {
    if (soundEnabled && _currentBgmState != BgmState.stopped) {
      _bgmPlayer.play();
    }
  }
}