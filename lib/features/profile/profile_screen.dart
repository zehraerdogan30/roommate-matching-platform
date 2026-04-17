import '../../app.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../onboarding/onboarding_screen.dart';
import '../../ui/blob_background.dart';
import '../../ui/glass_app_bar.dart';
import '../../ui/glass_card.dart';
import '../../ui/gradient_chip.dart';
import '../../ui/gradient_button.dart';
import '../../ui/bouncy_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime? birthDate;
  String? nationality;
  String? livingCountry;

  final schoolCtrl = TextEditingController();
  final cityCtrl = TextEditingController();

  bool loading = false;
  Map<String, dynamic>? answers;
  bool answersCompleted = false;

  User get user => FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    _loadProfileAndAnswers();
  }

  @override
  void dispose() {
    schoolCtrl.dispose();
    cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfileAndAnswers() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    if (!mounted) return;

    setState(() {
      final bd = data['birthDate'];
      if (bd is Timestamp) birthDate = bd.toDate();

      nationality = data['nationality'] as String?;
      livingCountry = data['country'] as String?;
      schoolCtrl.text = (data['school'] ?? '').toString();
      cityCtrl.text = (data['city'] ?? '').toString();

      answers = (data['answers'] as Map?)?.cast<String, dynamic>();
      answersCompleted = (data['answersCompleted'] == true);
    });
  }

  int _calcAge(DateTime b) {
    final now = DateTime.now();
    int age = now.year - b.year;
    final hadBirthdayThisYear =
        (now.month > b.month) || (now.month == b.month && now.day >= b.day);
    if (!hadBirthdayThisYear) age--;
    return age;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1950, 1, 1),
      lastDate: now,
    );
    if (picked != null) setState(() => birthDate = picked);
  }

  void _pickCountry({required bool forNationality}) {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country c) {
        setState(() {
          if (forNationality) {
            nationality = c.name;
          } else {
            livingCountry = c.name;
          }
        });
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (birthDate == null) return _toast('Doğum tarihini seç.');
    if (nationality == null) return _toast('Milliyet seç.');
    if (livingCountry == null) return _toast('Yaşadığın ülkeyi seç.');

    setState(() => loading = true);

    final age = _calcAge(birthDate!);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fullName': user.displayName ?? '',
      'email': user.email,
      'birthDate': Timestamp.fromDate(birthDate!),
      'age': age,
      'nationality': nationality,
      'country': livingCountry,
      'school': schoolCtrl.text.trim(),
      'city': cityCtrl.text.trim(),
      'profileCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() => loading = false);
    _toast('Kaydedildi ✅');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _dateLabel(DateTime? d) {
    if (d == null) return 'Seç';
    return '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.'
        '${d.year}';
  }

  String _prettySleep(String? v) {
    switch (v) {
      case 'early_bird':
        return 'Early bird';
      case 'balanced':
        return 'Balanced';
      case 'night_owl':
        return 'Night owl';
      default:
        return '-';
    }
  }

  String _prettyParties(String? v) {
    switch (v) {
      case 'never':
        return 'Never';
      case 'occasionally':
        return 'Occasionally';
      case 'often':
        return 'Often';
      default:
        return '-';
    }
  }

  Widget _kv(String k, String v, {required bool dark}) {
    final leftColor = dark ? Colors.white.withOpacity(0.70) : Colors.black.withOpacity(0.55);
    final rightColor = dark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: TextStyle(
                color: leftColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            v,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: rightColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = (user.displayName ?? 'User').trim();
    final name = displayName.isEmpty ? 'User' : displayName;

    final t = MyApp.of(context).theme;
    final dark = t.isDark;

    final sub = [
      if (schoolCtrl.text.trim().isNotEmpty) schoolCtrl.text.trim(),
      if (cityCtrl.text.trim().isNotEmpty) cityCtrl.text.trim(),
      if ((livingCountry ?? '').trim().isNotEmpty) (livingCountry ?? '').trim(),
    ].join(' • ');

    final a = answers ?? {};
    final hasAnswers = a.isNotEmpty;

    final subtleText = dark ? Colors.white.withOpacity(0.70) : Colors.black.withOpacity(0.60);

    return Scaffold(
      appBar: GlassAppBar(
        title: const Text('Profil'),
        actions: [
          // ✅ DARK MODE TOGGLE (ikon)
          IconButton(
            tooltip: 'Dark mode',
            icon: Icon(dark ? Icons.dark_mode : Icons.light_mode),
            onPressed: () => t.toggleDark(!dark),
          ),

          IconButton(
            tooltip: 'Yenile',
            onPressed: _loadProfileAndAnswers,
            icon: const Icon(Icons.refresh),
          ),
          TextButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            child: const Text('Çıkış'),
          ),
        ],
      ),
      body: BlobBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // HEADER
                GlassCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _avatar(name),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sub.isEmpty ? 'Profile ready for better matches ✨' : sub,
                              style: TextStyle(color: subtleText),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                GradientChip(
                                  text: answersCompleted ? 'Test: Completed ✅' : 'Test: Not completed',
                                ),
                                GradientChip(
                                  text: 'Age: ${birthDate == null ? '-' : _calcAge(birthDate!).toString()}',
                                ),
                                if ((nationality ?? '').isNotEmpty)
                                  GradientChip(text: 'Nationality: $nationality'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // TEST SUMMARY
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Test Cevapların (Özet)',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                          ),
                          const Spacer(),
                          BouncyButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                              ).then((_) => _loadProfileAndAnswers());
                            },
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                                ).then((_) => _loadProfileAndAnswers());
                              },
                              child: Text(hasAnswers ? 'Edit' : 'Start'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (!hasAnswers)
                        Text(
                          'Henüz test çözülmemiş. Eşleşme kalitesi için testi tamamla.',
                          style: TextStyle(color: subtleText),
                        )
                      else
                        Column(
                          children: [
                            _kv('Sleep schedule', _prettySleep(a['sleepSchedule']?.toString()), dark: dark),
                            _kv('Cleanliness', (a['cleanliness'] ?? '-').toString(), dark: dark),
                            _kv('Noise sensitivity', (a['noiseSensitivity'] ?? '-').toString(), dark: dark),
                            _kv('Talking', (a['talking'] ?? '-').toString(), dark: dark),
                            _kv('Parties', _prettyParties(a['parties']?.toString()), dark: dark),
                            _kv('Smell sensitivity', (a['smellSensitivity'] ?? '-').toString(), dark: dark),
                            _kv('Light sensitivity', (a['lightSensitivity'] ?? '-').toString(), dark: dark),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // PROFILE EDIT
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profil Bilgileri',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),

                      _niceTile(
                        dark: dark,
                        icon: Icons.cake_outlined,
                        title: 'Doğum tarihi',
                        subtitle: _dateLabel(birthDate),
                        onTap: _pickBirthDate,
                      ),
                      const SizedBox(height: 10),

                      _niceTile(
                        dark: dark,
                        icon: Icons.flag_outlined,
                        title: 'Milliyet',
                        subtitle: nationality ?? 'Seç',
                        onTap: () => _pickCountry(forNationality: true),
                      ),
                      const SizedBox(height: 10),

                      _niceTile(
                        dark: dark,
                        icon: Icons.public_outlined,
                        title: 'Yaşadığın ülke',
                        subtitle: livingCountry ?? 'Seç',
                        onTap: () => _pickCountry(forNationality: false),
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: schoolCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Okul / Kurum',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Okul yaz' : null,
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: cityCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Şehir',
                          prefixIcon: Icon(Icons.location_city_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Şehir yaz' : null,
                      ),

                      const SizedBox(height: 14),

                      GradientButton(
                        text: loading ? 'Kaydediliyor…' : 'Kaydet',
                        loading: loading,
                        icon: Icons.save_outlined,
                        onPressed: loading ? null : _saveProfile,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _niceTile({
    required bool dark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final tileColor = dark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.70);
    final borderColor = dark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.06);
    final titleColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.white.withOpacity(0.70) : Colors.black.withOpacity(0.60);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: tileColor,
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6E5AE6).withOpacity(0.20),
                    const Color(0xFFFF5EA8).withOpacity(0.14),
                    const Color(0xFF22D3EE).withOpacity(0.10),
                  ],
                ),
              ),
              child: Icon(icon, color: dark ? Colors.white.withOpacity(0.85) : Colors.black.withOpacity(0.75)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: titleColor)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: subColor)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: dark ? Colors.white.withOpacity(0.55) : Colors.black.withOpacity(0.45)),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String name) {
    final ch = name.isNotEmpty ? name.trim()[0].toUpperCase() : 'U';
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6E5AE6), Color(0xFFFF5EA8), Color(0xFF22D3EE)],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: const Color(0xFF6E5AE6).withOpacity(0.18),
          ),
        ],
      ),
      child: Text(
        ch,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
      ),
    );
  }
}
