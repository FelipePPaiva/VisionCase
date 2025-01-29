import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset getSquarePosition(double progress) {
    const sideLength = 40.0;
    final totalDistance = sideLength * 4;
    final distance = progress * totalDistance;

    if (distance <= sideLength) {
      return Offset(distance, 0);
    } else if (distance <= sideLength * 2) {
      return Offset(sideLength, distance - sideLength);
    } else if (distance <= sideLength * 3) {
      return Offset(sideLength - (distance - sideLength * 2), sideLength);
    } else {
      return Offset(0, sideLength - (distance - sideLength * 3));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: 100, // Ajuste esse valor conforme necessário
          height: 100,
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (_, __) {
                  final pos = getSquarePosition(_controller.value);
                  return Transform.translate(
                    offset: pos,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(0, 114, 239, 1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _controller,
                builder: (_, __) {
                  final pos = getSquarePosition((_controller.value + 0.5) % 1);
                  return Transform.translate(
                    offset: pos,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(0, 114, 239, 1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}