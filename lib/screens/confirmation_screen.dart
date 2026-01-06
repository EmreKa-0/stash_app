import 'package:flutter/material.dart';
import '../utils/app_styles.dart';

class ConfirmationScreen extends StatelessWidget {
  final String pickupCode;
  final String? shopName;
  final String? dateRange;
  final double? totalPrice;

  const ConfirmationScreen({
    super.key,
    required this.pickupCode,
    this.shopName,
    this.dateRange,
    this.totalPrice,
  });

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
              kLightOrange.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon:
                            Icon(Icons.arrow_back_ios_new, color: kPrimaryBlue),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Reservation Completed',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryBlue,
                      ),
                    ),
                  ],
                ),
              ),

              // Content - DÜZELTME BURADA BAŞLIYOR
              Expanded(
                // Ekran içeriğini kaydırılabilir yapmak için SingleChildScrollView eklendi.
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Success Icon
                        Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                kOrangeButton,
                                kOrangeButton.withOpacity(0.8)
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: kOrangeButton.withOpacity(0.4),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Success Message
                        Text(
                          'Your Stash is\nCreated Successfully!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: kPrimaryBlue,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        // Info Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kLightOrange, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: kOrangeButton.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              if (shopName != null) ...[
                                _buildInfoRow(
                                  Icons.store,
                                  'Shop',
                                  shopName!,
                                ),
                                Divider(height: 30, color: kLightBlue),
                              ],
                              if (dateRange != null) ...[
                                _buildInfoRow(
                                  Icons.calendar_today,
                                  'Duration',
                                  dateRange!,
                                ),
                                Divider(height: 30, color: kLightBlue),
                              ],
                              if (totalPrice != null) ...[
                                _buildInfoRow(
                                  Icons.payments,
                                  'Total',
                                  'TL ${totalPrice!.toStringAsFixed(2)}',
                                ),
                                Divider(height: 30, color: kLightBlue),
                              ],

                              // Pickup Code Section
                              Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.qr_code_2,
                                          color: kOrangeButton, size: 28),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Your Pickup Code',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: kPrimaryBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          kLightOrange,
                                          kLightBlue.withOpacity(0.3)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: kOrangeButton,
                                        width: 2,
                                      ),
                                    ),
                                    child: SelectableText(
                                      pickupCode,
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 4,
                                        color: kPrimaryBlue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Show this code to receive your items',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: kPrimaryBlue.withOpacity(0.6),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Back to Home Button
                        Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                kOrangeButton,
                                kOrangeButton.withOpacity(0.8)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: kOrangeButton.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.popUntil(
                                  context, (route) => route.isFirst);
                            },
                            icon: const Icon(Icons.home,
                                color: Colors.white, size: 24),
                            label: const Text(
                              'BACK TO HOME',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // DÜZELTME BURADA BİTİYOR
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kLightOrange.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: kOrangeButton, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: kPrimaryBlue.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kPrimaryBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
