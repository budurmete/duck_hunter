import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flame/input.dart';
import 'dart:math';

void main() {
  runApp(MyApp());
}

// Ana uygulama sınıfı
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Duck Hunt Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GameWidget(game: DuckHuntGame()),
      debugShowCheckedModeBanner: false, // Debug banner'ı kaldır
    );
  }
}

// Oyun sınıfı
// Oyun sınıfı
class DuckHuntGame extends FlameGame with TapDetector {
  late SpriteComponent duck;
  late SpriteComponent background;
  late TextComponent scoreText;
  late TextComponent timerText;
  late AudioPlayer _audioPlayer;
  final Random _random = Random();
  int score = 0;
  double timeLeft = 30.0; // 30 saniye
  bool _gameOver = false; // Oyun bitip bitmediğini kontrol etmek için
  double _moveTimer = 0; // Ördeğin hareket etme zamanlayıcısı
  double _moveInterval = 1.0; // Ördeğin hareket etme aralığı (saniye cinsinden)
  double _moveSpeed = 600.0; // Ördeğin hareket hızı (piksel/saniye)
  late Vector2 _startPosition;
  late Vector2 _endPosition;
  late Vector2 _currentDirection;
  late TextComponent restartButton;
  double _speedIncreaseInterval = 5.0; // Hız artış aralığı (saniye cinsinden)
  double _speedIncreaseTimer = 0; // Hız artış zamanlayıcısı

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _audioPlayer = AudioPlayer();
    await _audioPlayer.setSource(AssetSource('duck_flap.mp3'));

    // Arka plan resmini yükle
    final backgroundSprite = await loadSprite('arkaplan.jfif');
    background = SpriteComponent()
      ..sprite = backgroundSprite
      ..size = size // Ekran boyutuna göre ayarla
      ..position = Vector2.zero()
      ..anchor = Anchor.topLeft;
    add(background);

    // Ördek resmini yükle ve ekle
    final duckSprite = await loadSprite('duck.png');
    duck = SpriteComponent()
      ..sprite = duckSprite
      ..size = Vector2(100.0, 100.0)
      ..position = _randomPosition() // Ördek pozisyonunu ilk başlatmada ayarla
      ..anchor = Anchor.center;

    add(duck);

    // Skor metni
    scoreText = TextComponent(
      text: 'Score: $score',
      position: Vector2(10, 10),
      textRenderer: TextPaint(style: TextStyle(fontSize: 24, color: Colors.white)),
    );

    // Zaman metni
    timerText = TextComponent(
      text: 'Time: ${timeLeft.toStringAsFixed(0)}',
      position: Vector2(10, 40),
      textRenderer: TextPaint(style: TextStyle(fontSize: 24, color: Colors.white)),
    );

    add(scoreText);
    add(timerText);

    _startPosition = duck.position;
    _endPosition = _randomPosition();
    _currentDirection = (_endPosition - _startPosition).normalized();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Zamanı güncelle
    if (timeLeft > 0) {
      timeLeft -= dt;
      timerText.text = 'Time: ${timeLeft.toStringAsFixed(0)}';
    } else if (!_gameOver) {
      // Zaman dolduysa oyunu bitir
      gameOver();
    }

    if (!_gameOver) {
      _moveTimer -= dt;
      _speedIncreaseTimer -= dt;
      if (_moveTimer <= 0) {
        _moveTimer = _moveInterval;
        // Hareket etmek için yeni bir pozisyona yönlendir
        _startPosition = duck.position;
        _endPosition = _randomPosition();
        _currentDirection = (_endPosition - _startPosition).normalized();
      }

      _smoothMoveDuck(dt);

      // Her 5 saniyede bir hızı artır
      if (_speedIncreaseTimer <= 0) {
        _speedIncreaseTimer = _speedIncreaseInterval;
        _moveSpeed *= 1.1; // Hızı %10 artır
      }
    }
  }

  Vector2 _randomPosition() {
    final double duckWidth = 100.0;  // Ördeğin genişliği
    final double duckHeight = 100.0; // Ördeğin yüksekliği

    final double margin = 30.0; // Ekranın altından bırakılacak mesafe

    final x = _random.nextDouble() * (size.x - duckWidth); // Ekran genişliği - ördeğin genişliği
    final y = _random.nextDouble() * (size.y - duckHeight - margin); // Ekran yüksekliği - ördeğin yüksekliği - margin

    return Vector2(x, y);
  }

  void _smoothMoveDuck(double dt) {
    final distanceToTarget = (_endPosition - duck.position).length;

    if (distanceToTarget > _moveSpeed * dt) {
      duck.position += _currentDirection * _moveSpeed * dt;
    } else {
      duck.position = _endPosition;
      _startPosition = duck.position;
      _endPosition = _randomPosition();
      _currentDirection = (_endPosition - _startPosition).normalized();
    }
  }

  @override
  void onTapDown(TapDownInfo info) {
    if (_gameOver) {
      // Butona tıklama kontrolü
      if (restartButton.toRect().contains(info.eventPosition.global.toOffset())) {
        _restartGame();
      }
      return;
    }

    final touchPosition = info.eventPosition.global;
    if (duck.toRect().contains(touchPosition.toOffset())) {
      _audioPlayer.play(AssetSource('duck_dead.mp3')); // Ses çal
      score++;
      scoreText.text = 'Score: $score';

      // Ördeği vurduktan sonra rastgele bir yerde doğur
      _startPosition = duck.position;
      _endPosition = _randomPosition(); // Yeni pozisyon belirle
      _currentDirection = (_endPosition - _startPosition).normalized(); // Yönü ayarla
    }
  }

  void gameOver() {
    _gameOver = true; // Oyun bitti flag'ini ayarla

    final gameOverText = TextComponent(
      text: 'Game Over\nScore: $score',
      position: Vector2(size.x / 2, size.y / 2 - 50),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: TextStyle(fontSize: 48, color: Colors.red)),
    );

    restartButton = TextComponent(
      text: 'Tekrar Oyna',
      position: Vector2(size.x / 2, size.y / 2 + 50),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: TextStyle(fontSize: 32, color: Colors.white)),
    );

    add(gameOverText);
    add(restartButton);

    // Oyun bitince dokunma olayını engellemek için
    remove(duck);
  }

  void _restartGame() {
    // Game over ekranındaki tüm metinleri ve butonları kaldır
    final componentsToRemove = List<Component>.from(children.where((c) => c is TextComponent));

    // Game over metni ve restart butonu dahil tüm bileşenleri kaldır
    removeAll(componentsToRemove);

    // Yeni bir başlangıç yap
    score = 0;
    timeLeft = 30.0; // Zamanı yeniden başlat
    _gameOver = false;
    _moveTimer = 0; // Hareket zamanlayıcısını sıfırla
    _speedIncreaseTimer = _speedIncreaseInterval; // Hız artış zamanlayıcısını sıfırla

    // Ördeği yeniden oluştur ve ekrana ekle
    final duckSprite = loadSprite('duck.png').then((sprite) {
      duck
        ..sprite = sprite
        ..position = _randomPosition(); // Ördeğin yeni pozisyonunu ayarla
      add(duck);
    });

    // Skor ve zaman metinlerini yeniden oluştur ve ekrana ekle
    scoreText = TextComponent(
      text: 'Score: $score',
      position: Vector2(10, 10),
      textRenderer: TextPaint(style: TextStyle(fontSize: 24, color: Colors.white)),
    );

    timerText = TextComponent(
      text: 'Time: ${timeLeft.toStringAsFixed(0)}',
      position: Vector2(10, 40),
      textRenderer: TextPaint(style: TextStyle(fontSize: 24, color: Colors.white)),
    );

    add(scoreText);
    add(timerText);

    // Yeniden başlatma için diğer ayarları yap
    _startPosition = duck.position;
    _endPosition = _randomPosition();
    _currentDirection = (_endPosition - _startPosition).normalized();
    _moveTimer = _moveInterval;
  }
}

