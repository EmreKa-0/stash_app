import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import 'employee_registration_screen.dart';
import 'visitor_registration_screen.dart';
import 'login_screen.dart';

class SelectionScreen extends StatelessWidget {
  final bool comingFromMap; // Map'ten mi geldi?

  const SelectionScreen({
    super.key,
    this.comingFromMap = false,
  });

  Widget _buildSelectionButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required bool isVisitor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isVisitor
                ? [kLightOrange, kLightOrange.withOpacity(0.6)]
                : [kLightBlue, kLightBlue.withOpacity(0.6)],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isVisitor ? kOrangeButton : kPrimaryBlue,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  (isVisitor ? kOrangeButton : kPrimaryBlue).withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Icon(
                icon,
                size: 50,
                color: isVisitor ? kOrangeButton : kPrimaryBlue,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: kPrimaryBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: kPrimaryBlue.withOpacity(0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isVisitor
                      ? [kOrangeButton, kOrangeButton.withOpacity(0.8)]
                      : [kPrimaryBlue, kPrimaryBlue.withOpacity(0.8)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isVisitor ? kOrangeButton : kPrimaryBlue)
                        .withOpacity(0.4),
                    blurRadius: 8,
                  )
                ],
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kLightBlue,
              kLightBlue.withOpacity(0.8),
              kLightOrange.withOpacity(0.2),
            ],
          ),
        ),
        child: Stack(
          children: <Widget>[
            // Background Icon
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: 0.08,
                  child: Icon(
                    Icons.luggage_outlined,
                    size: MediaQuery.of(context).size.width * 1.2,
                    color: kPrimaryBlue,
                  ),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Back Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_ios_new,
                              color: kPrimaryBlue),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Logo
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kOrangeButton,
                            kOrangeButton.withOpacity(0.8)
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: kOrangeButton.withOpacity(0.4),
                            blurRadius: 25,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.cases_outlined,
                        size: 70,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 35),

                    // Main Title
                    Text(
                      'ENJOY THE LAST\nDAY OF YOUR\nTRIP',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kPrimaryBlue,
                        fontSize: 36,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: kOrangeButton.withOpacity(0.3),
                            offset: const Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 50),

                    // Subtitle
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kLightOrange.withOpacity(0.8),
                            kLightOrange.withOpacity(0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: kOrangeButton, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: kOrangeButton.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Text(
                        'WHO ARE YOU?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: kPrimaryBlue,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 35),

                    // Visitor Button
                    _buildSelectionButton(
                      context,
                      title: 'VISITOR',
                      subtitle: 'I need to store my baggage',
                      icon: Icons.cases_outlined,
                      isVisitor: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const VisitorRegistrationScreen(),
                          ),
                        );
                      },
                    ),

                    // Employee Button
                    _buildSelectionButton(
                      context,
                      title: 'BUSINESS',
                      subtitle: 'I want to offer storage service',
                      icon: Icons.storefront_outlined,
                      isVisitor: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const EmployeeRegistrationScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 50),

                    // Login Link
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: kPrimaryBlue.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Text(
                              'ALREADY HAVE AN ACCOUNT?',
                              style: TextStyle(
                                fontSize: 13,
                                color: kPrimaryBlue.withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    kOrangeButton,
                                    kOrangeButton.withOpacity(0.8)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: kOrangeButton.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'LOG IN',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
