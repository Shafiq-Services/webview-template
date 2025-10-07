import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_demo/constants/my_app_colors.dart';
import 'package:webview_demo/constants/my_app_urls.dart';
import 'package:webview_demo/view/screens/bottom_navigation_screen.dart';
import 'package:webview_demo/view/screens/webview_screens/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(image: 'assets/images/1.jpg'),
    OnboardingItem(image: 'assets/images/2.jpg'),
    OnboardingItem(image: 'assets/images/3.jpg'),
  ];
  final List<String> onBoardingTitle = [
    'FREE WONEP TO WONEP',
    'SIMPLE ABROAD CALLS',
    'NO HIDDEN CHARGES OR FEES',
  ];
  final List<String> onBoardingText = [
    'If the Person you are calling, also has the WONEPWONEP, the call will be entirely free',
    'WONEP converts international calls to local calls without wifi or data',
    'We have a very small charge of non WONEP call to mobile or landlines',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {});
  }

  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        height: size.height,
        width: size.width,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return OnboardingPage(
                  text: onBoardingText[index],
                  item: _items[index],
                  label: onBoardingTitle[index],
                );
              },
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height / 30,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _items.length,
                      (index) => buildDotIndicator(index),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height / 50),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_currentPage == _items.length - 1) {
                              navigateToHome();
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeIn,
                              );
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: Colors.lightBlue,
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width / 7,
                                vertical:
                                    MediaQuery.of(context).size.width / 42,
                              ),
                              child: Text(
                                _currentPage == _items.length - 1
                                    ? "Get Started"
                                    : 'Next',
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width / 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => navigateToHome(),
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width / 28,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDotIndicator(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: MediaQuery.of(context).size.width / 50,
      height: MediaQuery.of(context).size.width / 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index
            ? Colors.lightBlue
            : Colors.lightBlue.withOpacity(0.2),
      ),
    );
  }

  void navigateToHome() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isFirstTime', false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }
}

class OnboardingItem {
  final String image;

  OnboardingItem({required this.image});
}

class OnboardingPage extends StatelessWidget {
  final OnboardingItem item;
  final String label;
  final String text;

  const OnboardingPage({
    Key? key,
    required this.item,
    required this.text,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MyColors.konboardingBgColor,
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Image.asset(
            item.image,
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
          ),
          // SizedBox(
          //   height: MediaQuery.of(context).size.height / 4,
          // ),
          // Text(
          //   label,
          //   maxLines: 2,
          //   textAlign: TextAlign.center,
          //   style: TextStyle(
          //     fontWeight: FontWeight.bold,
          //     fontSize: MediaQuery.of(context).size.width / 16,
          //     color: Colors.black,
          //   ),
          // ),
          // SizedBox(height: MediaQuery.of(context).size.height / 80),
          // Text(
          //   text,
          //   maxLines: 2,
          //   textAlign: TextAlign.center,
          //   style: TextStyle(
          //     fontWeight: FontWeight.normal,
          //     fontSize: MediaQuery.of(context).size.width / 28,
          //     color: Colors.grey,
          //   ),
          // ),
        ],
      ),
    );
  }
}
