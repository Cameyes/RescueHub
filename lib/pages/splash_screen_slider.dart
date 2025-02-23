import 'package:flutter/material.dart';
import 'package:food_delivery_app/pages/login_page.dart';
import 'package:food_delivery_app/pages/splash_one.dart';
import 'package:food_delivery_app/pages/splash_two.dart';
import 'package:food_delivery_app/pages/splash_three.dart';


class SplashScreenSlider extends StatelessWidget {
  final PageController _controller = PageController();

  SplashScreenSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PageView for sliding screens
          PageView(
            controller: _controller,
            children: const [
              SplashOne(),
              SplashTwo(),
              SplashThree(),
            ],
          ),
          
          // Navigation dots
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: DotsIndicator(controller: _controller),
          ),
          
          // Skip button
          Positioned(
            top: 50,
            right: 20,
            child: StreamBuilder<int>(
              stream: Stream.periodic(const Duration(milliseconds: 100), (_) {
                return _controller.hasClients ? _controller.page?.round() ?? 0 : 0;
              }),
              builder: (context, snapshot) {
                final currentPage = snapshot.data ?? 0;
                
                // Hide skip button on the last page
                if (currentPage == 2) {
                  return const SizedBox.shrink();
                }
                
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>loginScreen()));
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Skip',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.skip_next_rounded,
                              color: Colors.black,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Dots indicator for showing current page
class DotsIndicator extends StatelessWidget {
  final PageController controller;

  const DotsIndicator({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(milliseconds: 100), (_) {
        return controller.hasClients ? controller.page?.round() ?? 0 : 0;
      }),
      builder: (context, snapshot) {
        final currentPage = snapshot.data ?? 0;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 100),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: currentPage == index 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey[800],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
