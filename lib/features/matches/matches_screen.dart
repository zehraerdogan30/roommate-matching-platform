import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../profile/profile_screen.dart';
import '../requests/requests_inbox_screen.dart';

// ✅ UI helpers (bunlar yoksa altta dosyalarını da vereceğim)
import '../../ui/glass_card.dart';
import '../../ui/gradient_chip.dart';
import '../../ui/bouncy_button.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final _me = FirebaseAuth.instance.currentUser!;
  Map<String, dynamic>? myData;

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  Future<void> _loadMe() async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(_me.uid).get();
    if (!doc.exists) return;
    if (!mounted) return;
    setState(() => myData = doc.data());
  }

  // ===== REQUEST HELPERS =====
  String _reqId(String otherUid) => '${_me.uid}__${otherUid}';

  Stream<DocumentSnapshot<Map<String, dynamic>>> _requestStream(String otherUid) {
    return FirebaseFirestore.instance
        .collection('requests')
        .doc(_reqId(otherUid))
        .snapshots();
  }

  Future<bool> _sendRequest(String toUid) async {
    final fromUid = _me.uid;
    if (fromUid == toUid) return false;

    final docId = '${fromUid}__${toUid}';
    final ref = FirebaseFirestore.instance.collection('requests').doc(docId);

    return FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);

      if (snap.exists) {
        final status = snap.data()?['status'];
        if (status == 'pending' || status == 'accepted') return false;

        // declined → tekrar pending
        tx.set(
          ref,
          {
            'fromUid': fromUid,
            'toUid': toUid,
            'status': 'pending',
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        return true;
      }

      tx.set(ref, {
        'fromUid': fromUid,
        'toUid': toUid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (myData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final myAnswers =
        (myData!['answers'] as Map?)?.cast<String, dynamic>() ?? {};
    final myCity = (myData!['city'] ?? '').toString().trim();
    final myCountry = (myData!['country'] ?? '').toString().trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
        actions: [
          // Requests Inbox
          IconButton(
            icon: const Icon(Icons.mail_outline),
            tooltip: 'Requests',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RequestsInboxScreen()),
              );
            },
          ),

          // Profile
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),

          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadMe,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('profileCompleted', isEqualTo: true)
            .where('answersCompleted', isEqualTo: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs.where((d) => d.id != _me.uid).toList();

          final scored = docs.map((d) {
            final data = d.data();
            final answers =
                (data['answers'] as Map?)?.cast<String, dynamic>() ?? {};
            final score = _calcScore(myAnswers, answers);

            double locationBonus = 0;
            final ctry = (data['country'] ?? '').toString().trim();
            final city = (data['city'] ?? '').toString().trim();
            if (myCountry.isNotEmpty && ctry == myCountry) locationBonus += 4;
            if (myCity.isNotEmpty && city == myCity) locationBonus += 6;

            return _MatchCardData(
              uid: d.id,
              fullName: (data['fullName'] ?? 'User').toString(),
              school: (data['school'] ?? '').toString(),
              city: city,
              country: ctry,
              score: (score + locationBonus).clamp(0, 100).toDouble(),
              reasons: _topReasons(myAnswers, answers),
            );
          }).toList()
            ..sort((a, b) => b.score.compareTo(a.score));

          if (scored.isEmpty) {
            return const Center(child: Text('No matches yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: scored.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _matchCard(scored[i]),
          );
        },
      ),
    );
  }

  // ===== MATCHING =====

  double _calcScore(Map<String, dynamic> a, Map<String, dynamic> b) {
    const weights = {
      'sleepSchedule': 15,
      'cleanliness': 18,
      'noiseSensitivity': 18,
      'talking': 14,
      'parties': 15,
      'smellSensitivity': 10,
      'lightSensitivity': 10,
    };

    double earned = 0;
    double total = 0;

    for (final e in weights.entries) {
      final va = a[e.key];
      final vb = b[e.key];
      if (va == null || vb == null) continue;

      total += e.value;

      if (e.key == 'sleepSchedule' || e.key == 'parties') {
        earned += e.value * _catSimilarity(va.toString(), vb.toString(), e.key);
      } else {
        final ia = _toInt(va);
        final ib = _toInt(vb);
        if (ia == null || ib == null) continue;
        earned += e.value * (1 - ((ia - ib).abs() / 4)).clamp(0.0, 1.0);
      }
    }

    if (total == 0) return 0;
    return (earned / total) * 100;
  }

  double _catSimilarity(String a, String b, String key) {
    if (a == b) return 1;
    const map = {
      'sleepSchedule': ['early_bird', 'balanced', 'night_owl'],
      'parties': ['never', 'occasionally', 'often'],
    };
    final list = map[key]!;
    final diff = (list.indexOf(a) - list.indexOf(b)).abs();
    if (diff == 1) return 0.6;
    return 0;
  }

  int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString());
  }

  List<String> _topReasons(Map<String, dynamic> a, Map<String, dynamic> b) {
    final reasons = <String>[];

    void check(String key, String label) {
      final ia = _toInt(a[key]);
      final ib = _toInt(b[key]);
      if (ia != null && ib != null && (ia - ib).abs() <= 1) {
        reasons.add(label);
      }
    }

    check('cleanliness', 'Similar cleanliness level');
    check('noiseSensitivity', 'Similar noise tolerance');
    check('talking', 'Similar social level');

    return reasons.take(3).toList();
  }

  // ===== UI =====

  Widget _matchCard(_MatchCardData m) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  m.fullName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              GradientChip(text: '${m.score.toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [m.school, m.city, m.country].where((e) => e.isNotEmpty).join(' • '),
            style: TextStyle(color: Colors.black.withOpacity(0.55)),
          ),
          const SizedBox(height: 10),

          if (m.reasons.isNotEmpty) ...[
            ...m.reasons.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $r',
                  style: TextStyle(color: Colors.black.withOpacity(0.72)),
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],

          // CONNECT BUTTON (SMART)
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _requestStream(m.uid),
            builder: (context, snap) {
              final exists = snap.data?.exists == true;
              final status = (snap.data?.data()?['status'] ?? '').toString();

              String text = 'Connect';
              bool disabled = false;

              if (exists && status == 'pending') {
                text = 'Pending…';
                disabled = true;
              } else if (exists && status == 'accepted') {
                text = 'Connected ✅';
                disabled = true;
              }

              return BouncyButton(
                onPressed: disabled
                    ? null
                    : () async {
                        final ok = await _sendRequest(m.uid);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok ? 'Request sent!' : 'Request already exists'),
                          ),
                        );
                      },
                child: OutlinedButton(
                  onPressed: null, // BouncyButton yönetiyor
                  child: Text(text),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MatchCardData {
  final String uid;
  final String fullName;
  final String school;
  final String city;
  final String country;
  final double score;
  final List<String> reasons;

  _MatchCardData({
    required this.uid,
    required this.fullName,
    required this.school,
    required this.city,
    required this.country,
    required this.score,
    required this.reasons,
  });
}
