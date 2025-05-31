import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(BucketBallGame());
}

class BucketBallGame extends StatelessWidget {
  const BucketBallGame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bucket Ball Collector',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial',
      ),
      home: const GameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Ball {
  double x;
  double y;
  double speed;
  Color color;
  double size;

  Ball({
    required this.x,
    required this.y,
    required this.speed,
    required this.color,
    required this.size,
  });
}

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  List<Ball> balls = [];
  double bucketX = 150;
  double bucketY = 500;
  double bucketWidth = 80;
  double bucketHeight = 40;
  int score = 0;
  int lives = 3;
  bool isGameRunning = false;
  Timer? gameTimer;
  Timer? ballSpawnTimer;
  late AnimationController _bucketController;
  late Animation<double> _bucketAnimation;

  final Random random = Random();
  final List<Color> ballColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
  ];

  @override
  void initState() {
    super.initState();
    _bucketController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _bucketAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _bucketController, curve: Curves.elasticOut),
    );
  }

  void startGame() {
    setState(() {
      isGameRunning = true;
      score = 0;
      lives = 3;
      balls.clear();
      // Reset bucket position
      bucketX = 150;
    });

    // Game loop - updates ball positions
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!isGameRunning) {
        timer.cancel();
        return;
      }
      updateGame();
    });

    // Spawn new balls
    ballSpawnTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (!isGameRunning) {
        timer.cancel();
        return;
      }
      spawnBall();
    });
  }

  void spawnBall() {
    if (!mounted) return;

    double screenWidth = MediaQuery.of(context).size.width;
    setState(() {
      balls.add(Ball(
        x: random.nextDouble() * (screenWidth - 30),
        y: -30,
        speed: 2 + random.nextDouble() * 3,
        color: ballColors[random.nextInt(ballColors.length)],
        size: 20 + random.nextDouble() * 15,
      ));
    });
  }

  void updateGame() {
    if (!mounted) return;

    setState(() {
      // Update ball positions
      for (int i = balls.length - 1; i >= 0; i--) {
        balls[i].y += balls[i].speed;

        // Check collision with bucket
        if (balls[i].y + balls[i].size >= bucketY &&
            balls[i].y <= bucketY + bucketHeight &&
            balls[i].x + balls[i].size >= bucketX &&
            balls[i].x <= bucketX + bucketWidth) {
          // Ball caught!
          score += 10;
          balls.removeAt(i);
          _bucketController.forward().then((_) {
            if (mounted) {
              _bucketController.reverse();
            }
          });
          continue;
        }

        // Remove balls that fell off screen
        if (balls[i].y > MediaQuery.of(context).size.height) {
          balls.removeAt(i);
          lives--;
          if (lives <= 0) {
            gameOver();
          }
        }
      }
    });
  }

  void gameOver() {
    setState(() {
      isGameRunning = false;
    });
    gameTimer?.cancel();
    ballSpawnTimer?.cancel();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Game Over!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sports_basketball, size: 50, color: Colors.orange),
              const SizedBox(height: 10),
              Text('Final Score: $score', style: const TextStyle(fontSize: 20)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                startGame();
              },
              child: const Text('Play Again'),
            ),
          ],
        );
      },
    );
  }

  void moveBucket(double deltaX) {
    if (!mounted) return;

    setState(() {
      bucketX += deltaX;
      double screenWidth = MediaQuery.of(context).size.width;
      if (bucketX < 0) bucketX = 0;
      if (bucketX > screenWidth - bucketWidth) {
        bucketX = screenWidth - bucketWidth;
      }
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    ballSpawnTimer?.cancel();
    _bucketController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    // Update bucket position based on screen size
    bucketY = screenHeight - 150;

    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      appBar: AppBar(
        title: const Text('Bucket Ball Collector'),
        backgroundColor: Colors.blue[600],
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background pattern
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.lightBlue[100]!, Colors.lightBlue[50]!],
              ),
            ),
          ),

          // Game Area
          if (isGameRunning) ...[
            // Balls
            ...balls.map((ball) => Positioned(
              left: ball.x,
              top: ball.y,
              child: Container(
                width: ball.size,
                height: ball.size,
                decoration: BoxDecoration(
                  color: ball.color,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
            )).toList(),

            // Bucket
            Positioned(
              left: bucketX,
              top: bucketY,
              child: AnimatedBuilder(
                animation: _bucketAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _bucketAnimation.value,
                    child: Container(
                      width: bucketWidth,
                      height: bucketHeight,
                      decoration: BoxDecoration(
                        color: Colors.brown[600],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                        ),
                        border: Border.all(color: Colors.brown[800]!, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(3, 3),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Game Controls
          if (isGameRunning) ...[
            Positioned(
              bottom: 50,
              left: 20,
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () => moveBucket(-30),
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(15),
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                    child: const Icon(Icons.arrow_left, size: 30),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () => moveBucket(30),
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(15),
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                    child: const Icon(Icons.arrow_right, size: 30),
                  ),
                ],
              ),
            ),
          ],

          // Score and Lives Display
          if (isGameRunning) ...[
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Score: $score',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Text('Lives: ', style: TextStyle(fontSize: 16)),
                        ...List.generate(lives, (index) =>
                        const Icon(Icons.favorite, color: Colors.red, size: 20)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Start Game Button
          if (!isGameRunning) ...[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.games, size: 100, color: Colors.blue[600]),
                  const SizedBox(height: 20),
                  Text(
                    'Bucket Ball Collector',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Catch the falling balls with your bucket!',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 5,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      child: Text(
                        'START GAME',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}