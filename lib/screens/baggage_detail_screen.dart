import 'package:emanet/screens/confirmation_screen.dart';
import 'package:flutter/material.dart';
import 'map_screen.dart'; //Harita import edildi

// --- YENİ EKLENDİ (Çıkış için) ---
import 'selection_screen.dart';
// --- BİTİŞ ---

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
    'Baggage (Big)',
    'Baggage (Medium)',
    'Backpack',
    'Case',
    'Other',
  ];

  void _navigateToConfirmation() {
    if (_selectedBaggageType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a stash type.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConfirmationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          false, // Klavye açılınca haritanın bozulmasını engeller
      appBar: AppBar(
        title: const Text('Stash detailsx'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Exit',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => const SelectionScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ÜST KISIM: Emanet Seçimi (Scroll edilebilir değil, sabit alan)
          Container(
            padding: const EdgeInsets.all(20.0),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Emanet Türü',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedBaggageType,
                  items: _baggageTypes
                      .map((val) =>
                          DropdownMenuItem(value: val, child: Text(val)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedBaggageType = val),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCountButton(Icons.remove, () {
                      if (_baggageCount > 1) setState(() => _baggageCount--);
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text('$_baggageCount',
                          style: const TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold)),
                    ),
                    _buildCountButton(Icons.add, () {
                      setState(() => _baggageCount++);
                    }),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _navigateToConfirmation,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('EMANETİ ONAYLA',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // ALT KISIM: Harita (Geriye kalan tüm alanı kaplar)
          const Expanded(
            child: MapScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildCountButton(IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 50,
      height: 50,
      child: FloatingActionButton(
        heroTag: icon.codePoint.toString(),
        onPressed: onPressed,
        mini: true,
        backgroundColor: Colors.grey[200],
        elevation: 1,
        child: Icon(icon, color: Colors.black),
      ),
    );
  }
}
