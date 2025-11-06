import 'package:emanet/screens/confirmation_screen.dart';
import 'package:flutter/material.dart';

class BaggageDetailScreen extends StatefulWidget {
  const BaggageDetailScreen({super.key});

  @override
  State<BaggageDetailScreen> createState() => _BaggageDetailScreenState();
}

class _BaggageDetailScreenState extends State<BaggageDetailScreen> {
  int _baggageCount = 1;

  // Örnek: Emanet türünü seçmek için
  String? _selectedBaggageType;
  final List<String> _baggageTypes = [
    'Valiz (Büyük)',
    'Valiz (Orta)',
    'Sırt Çantası',
    'Kutu',
    'Diğer',
  ];

  void _navigateToConfirmation() {
    if (_selectedBaggageType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir emanet türü seçiniz.')),
      );
      return;
    }

    print('Emanet Kaydedildi: $_baggageCount adet $_selectedBaggageType');

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConfirmationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emanet Detayları'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Emanet Türü ve Sayısını Belirtin:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),

            // Emanet Türü Seçimi
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Emanet Türü',
                prefixIcon: Icon(Icons.category),
              ),
              value: _selectedBaggageType,
              hint: const Text('Seçiniz'),
              items: _baggageTypes
                  .map(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
              onChanged: (String? newValue) {
                setState(() => _selectedBaggageType = newValue);
              },
              validator: (value) =>
                  value == null ? 'Tür seçimi zorunludur.' : null,
            ),
            const SizedBox(height: 40),

            // Emanet Sayısı Ayarlayıcı
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCountButton(Icons.remove, () {
                  if (_baggageCount > 1) {
                    setState(() => _baggageCount--);
                  }
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Text(
                    '$_baggageCount',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
                _buildCountButton(Icons.add, () {
                  setState(() => _baggageCount++);
                }),
              ],
            ),
            const SizedBox(height: 10),
            const Center(child: Text('Eşya Sayısı')),
            const SizedBox(height: 50),

            // Onay Butonu
            ElevatedButton(
              onPressed: _navigateToConfirmation,
              child: const Text('EMANETİ ONAYLA'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountButton(IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 60,
      height: 60,
      child: FloatingActionButton(
        heroTag: icon.codePoint
            .toString(), // Aynı ekranda birden fazla FAB varsa hata vermemesi için
        onPressed: onPressed,
        child: Icon(icon, size: 30),
      ),
    );
  }
}
