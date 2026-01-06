class Validators {
  // 1. Global İsim Kontrolü
  static String? validateName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Name is required';
    }
    // Regex: letters, spaces, hyphen, apostrophe
    final nameExp = RegExp(r"^[\p{L}\s\-']+$", unicode: true);
    
    if (!nameExp.hasMatch(trimmed)) {
      return 'Invalid characters (no numbers/symbols)';
    }
    if (trimmed.length < 2) return 'Too short';
    if (trimmed.length > 50) return 'Too long';
    return null;
  }

  // 2. Global Telefon Numarası (GÜNCELLENDİ: Parantezleri de temizler)
  static String? validatePhone(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Phone number is required';
    }
    // Normalize to digits, keep leading + if present
    final hasPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7 || digits.length > 15) {
      return 'Invalid phone format';
    }
    if (hasPlus && !RegExp(r'^\+\d{7,15}$').hasMatch('+' + digits)) {
      return 'Invalid phone format';
    }
    return null;
  }

  // 3. Fiyat Kontrolü
  static String? validatePrice(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Required';
    final price = double.tryParse(trimmed);
    if (price == null) return 'Invalid number';
    if (price <= 0) return 'Must be > 0';
    if (price > 10000) return 'Max limit exceeded';
    return null;
  }

  // 4. Email Kontrolü
  static String? validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Email is required';
    final emailExp = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailExp.hasMatch(trimmed)) return 'Invalid email address';
    return null;
  }

  // 5. Bavul Sayısı
  static String? validateBagCount(String? value, {int max = 50}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Required';
    final count = int.tryParse(trimmed);
    if (count == null) return 'Invalid number';
    if (count <= 0) return 'Must be at least 1';
    if (count > max) return 'Max limit is $max';
    return null;
  }

  // 6. Tarih Kontrolü
  static String? validateDateRange(DateTime dropOff, DateTime pickUp) {
    if (pickUp.isBefore(dropOff)) return 'Pick-up cannot be before drop-off';
    if (dropOff.isBefore(DateTime.now().subtract(const Duration(minutes: 10)))) {
      return 'Cannot select past time';
    }
    return null;
  }
}
