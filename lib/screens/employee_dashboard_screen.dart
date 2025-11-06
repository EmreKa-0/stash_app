import 'package:flutter/material.dart';

class EmployeeDashboardScreen extends StatelessWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emanetçi Paneli'),
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Uygulamayı ana ekrana döndürerek çıkış yapar
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Hoş Geldiniz, Emanetçi!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 40),

            // Barokd Okut Butonu
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Barkod Okuyucu Açılıyor...')),
                );
                // Gerçek barkod okuyucu kodu buraya gelecek
              },
              label: const Text('EMANET AL / TESLİM ET'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 25,
                  horizontal: 30,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Emanet Listesi Butonu
            ElevatedButton.icon(
              icon: const Icon(Icons.list_alt),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Aktif Emanetler Listeleniyor...'),
                  ),
                );
                // Emanet listesi ekranına geçiş kodu buraya gelecek
              },
              label: const Text('AKTİF EMANETLERİ GÖR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade300,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  vertical: 25,
                  horizontal: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
