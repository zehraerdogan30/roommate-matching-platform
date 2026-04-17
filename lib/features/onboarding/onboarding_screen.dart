import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../matches/matches_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  int step = 0;
  bool saving = false;

  // ===== CORE answers =====
  String sleepSchedule = 'balanced'; // early_bird / balanced / night_owl
  int smellSensitivity = 3; // 1-5
  int lightSensitivity = 3; // 1-5
  String parties = 'never'; // never / occasionally / often
  int cleanliness = 3; // 1-5
  int noiseSensitivity = 3; // 1-5
  int talking = 3; // 1-5

  // ===== CONDITIONAL answers =====
  String? partyEndTime; // before_10 / midnight / after_midnight
  String? overnightGuests; // never / sometimes / often

  final Set<String> smellTriggers = {}; // food / smoke / perfume / chemicals
  String? strongCookingSmells; // ok / sometimes_uncomfortable / very_uncomfortable

  final Set<String> noiseTriggers = {}; // music / talking / tv / kitchen

  String? cleaningFrequency; // daily / every_few_days / weekly

  String? minimalInteraction; // yes / neutral / no
  String? dailySocial; // yes / sometimes / no

  bool get showPartyFollowups => parties != 'never';
  bool get showSmellFollowups => smellSensitivity >= 4;
  bool get showNoiseFollowups => noiseSensitivity >= 4;
  bool get showCleanFollowups => cleanliness >= 4;
  bool get showTalkLowFollowup => talking <= 2;
  bool get showTalkHighFollowup => talking >= 4;

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Map<String, dynamic> _buildAnswersMap() {
    return <String, dynamic>{
      // core
      'sleepSchedule': sleepSchedule,
      'smellSensitivity': smellSensitivity,
      'lightSensitivity': lightSensitivity,
      'parties': parties,
      'cleanliness': cleanliness,
      'noiseSensitivity': noiseSensitivity,
      'talking': talking,

      // conditional
      if (showPartyFollowups) 'partyEndTime': partyEndTime,
      if (showPartyFollowups) 'overnightGuests': overnightGuests,

      if (showSmellFollowups) 'smellTriggers': smellTriggers.toList(),
      if (showSmellFollowups) 'strongCookingSmells': strongCookingSmells,

      if (showNoiseFollowups) 'noiseTriggers': noiseTriggers.toList(),

      if (showCleanFollowups) 'cleaningFrequency': cleaningFrequency,

      if (showTalkLowFollowup) 'minimalInteraction': minimalInteraction,
      if (showTalkHighFollowup) 'dailySocial': dailySocial,
    };
  }

  Future<void> _saveToFirestore({required bool finalSubmit}) async {
    setState(() => saving = true);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'answers': _buildAnswersMap(),
      'answersCompleted': finalSubmit,
      'answersUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() => saving = false);
  }

  bool _validateStep(int s) {
    if (s == 0) return true;

    if (s == 1) {
      if (showPartyFollowups) {
        if (partyEndTime == null) {
          _toast('Please select: How late do gatherings usually last?');
          return false;
        }
        if (overnightGuests == null) {
          _toast('Please select: Do guests stay overnight?');
          return false;
        }
      }
      if (showCleanFollowups && cleaningFrequency == null) {
        _toast('Please select: How often do you clean shared areas?');
        return false;
      }
      return true;
    }

    if (s == 2) {
      if (showSmellFollowups) {
        if (smellTriggers.isEmpty) {
          _toast('Select at least one: Which smells bother you the most?');
          return false;
        }
        if (strongCookingSmells == null) {
          _toast('Please select: Strong cooking smells?');
          return false;
        }
      }

      if (showNoiseFollowups && noiseTriggers.isEmpty) {
        _toast('Select at least one: What noise bothers you the most?');
        return false;
      }

      if (showTalkLowFollowup && minimalInteraction == null) {
        _toast('Please select: Prefer minimal interaction?');
        return false;
      }

      if (showTalkHighFollowup && dailySocial == null) {
        _toast('Please select: Need daily social interaction?');
        return false;
      }

      return true;
    }

    return true;
  }

  Future<void> _next() async {
    if (!_validateStep(step)) return;

    // Her adım sonunda kaydet (final değil)
    await _saveToFirestore(finalSubmit: false);

    if (step < 2) {
      setState(() => step++);
      return;
    }

    // Final: answersCompleted = true
    await _saveToFirestore(finalSubmit: true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MatchesScreen()),
    );
  }

  void _back() {
    if (step == 0) return;
    setState(() => step--);
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (step) {
      0 => 'Step 1/3 • Basics',
      1 => 'Step 2/3 • Lifestyle',
      _ => 'Step 3/3 • Sensitivities',
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AbsorbPointer(
        absorbing: saving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (saving) const LinearProgressIndicator(minHeight: 3),
              const SizedBox(height: 10),

              _stepHeader(),
              const SizedBox(height: 12),

              if (step == 0) _step0(),
              if (step == 1) _step1(),
              if (step == 2) _step2(),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: step == 0 ? null : _back,
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _next,
                      child: Text(step == 2 ? 'Finish' : 'Next'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepHeader() {
    final progress = (step + 1) / 3.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        // progress bar üstte zaten var, burada sadece açıklama var
        Text('Answer honestly for better matches. Most questions are quick sliders.'),
        SizedBox(height: 8),
      ],
    );
  }

  // ====== STEP 0 ======
  Widget _step0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          title: 'How would you describe your sleep schedule?',
          child: _radioGroup<String>(
            value: sleepSchedule,
            options: const {
              'early_bird': 'Early bird',
              'balanced': 'Balanced',
              'night_owl': 'Night owl',
            },
            onChanged: (v) => setState(() => sleepSchedule = v),
          ),
        ),
        const SizedBox(height: 12),

        _card(
          title: 'How sensitive are you to smells (food, perfume, smoke)?',
          child: _sliderInt(
            value: smellSensitivity,
            min: 1,
            max: 5,
            label: smellSensitivity.toString(),
            onChanged: (v) => setState(() => smellSensitivity = v),
          ),
        ),
        const SizedBox(height: 12),

        _card(
          title: 'How sensitive are you to light while resting or sleeping?',
          child: _sliderInt(
            value: lightSensitivity,
            min: 1,
            max: 5,
            label: lightSensitivity.toString(),
            onChanged: (v) => setState(() => lightSensitivity = v),
          ),
        ),
        const SizedBox(height: 12),

        _card(
          title: 'How often do you have parties or social gatherings at home?',
          child: _radioGroup<String>(
            value: parties,
            options: const {
              'never': 'Never',
              'occasionally': 'Occasionally',
              'often': 'Often',
            },
            onChanged: (v) => setState(() {
              parties = v;
              if (!showPartyFollowups) {
                partyEndTime = null;
                overnightGuests = null;
              }
            }),
          ),
        ),
      ],
    );
  }

  // ====== STEP 1 ======
  Widget _step1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          title: 'How important is cleanliness for you?',
          child: _sliderInt(
            value: cleanliness,
            min: 1,
            max: 5,
            label: cleanliness.toString(),
            onChanged: (v) => setState(() {
              cleanliness = v;
              if (!showCleanFollowups) cleaningFrequency = null;
            }),
          ),
        ),
        const SizedBox(height: 12),

        if (showCleanFollowups) ...[
          _card(
            title: 'How often do you clean shared areas?',
            child: _radioGroup<String>(
              value: cleaningFrequency,
              options: const {
                'daily': 'Daily',
                'every_few_days': 'Every few days',
                'weekly': 'Weekly',
              },
              onChanged: (v) => setState(() => cleaningFrequency = v),
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (showPartyFollowups) ...[
          _card(
            title: 'How late do your gatherings usually last?',
            child: _radioGroup<String>(
              value: partyEndTime,
              options: const {
                'before_10': 'Before 10 PM',
                'midnight': 'Until midnight',
                'after_midnight': 'After midnight',
              },
              onChanged: (v) => setState(() => partyEndTime = v),
            ),
          ),
          const SizedBox(height: 12),
          _card(
            title: 'Do guests usually stay overnight?',
            child: _radioGroup<String>(
              value: overnightGuests,
              options: const {
                'never': 'Never',
                'sometimes': 'Sometimes',
                'often': 'Often',
              },
              onChanged: (v) => setState(() => overnightGuests = v),
            ),
          ),
          const SizedBox(height: 12),
        ],

        _card(
          title: 'How sensitive are you to noise at home?',
          child: _sliderInt(
            value: noiseSensitivity,
            min: 1,
            max: 5,
            label: noiseSensitivity.toString(),
            onChanged: (v) => setState(() {
              noiseSensitivity = v;
              if (!showNoiseFollowups) noiseTriggers.clear();
            }),
          ),
        ),
      ],
    );
  }

  // ====== STEP 2 ======
  Widget _step2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          title: 'How much do you like talking and socializing at home?',
          child: _sliderInt(
            value: talking,
            min: 1,
            max: 5,
            label: talking.toString(),
            onChanged: (v) => setState(() {
              talking = v;
              if (!showTalkLowFollowup) minimalInteraction = null;
              if (!showTalkHighFollowup) dailySocial = null;
            }),
          ),
        ),
        const SizedBox(height: 12),

        if (showTalkLowFollowup) ...[
          _card(
            title: 'Do you prefer minimal interaction at home?',
            child: _radioGroup<String>(
              value: minimalInteraction,
              options: const {
                'yes': 'Yes',
                'neutral': 'Neutral',
                'no': 'No',
              },
              onChanged: (v) => setState(() => minimalInteraction = v),
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (showTalkHighFollowup) ...[
          _card(
            title: 'Do you need daily social interaction at home?',
            child: _radioGroup<String>(
              value: dailySocial,
              options: const {
                'yes': 'Yes',
                'sometimes': 'Sometimes',
                'no': 'No',
              },
              onChanged: (v) => setState(() => dailySocial = v),
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (showSmellFollowups) ...[
          _card(
            title: 'Which smells bother you the most? (select all that apply)',
            child: _chipsMultiSelect(
              options: const {
                'food': 'Food',
                'smoke': 'Smoke',
                'perfume': 'Perfume',
                'chemicals': 'Cleaning chemicals',
              },
              selected: smellTriggers,
              onToggle: (k) => setState(() {
                if (smellTriggers.contains(k)) {
                  smellTriggers.remove(k);
                } else {
                  smellTriggers.add(k);
                }
              }),
            ),
          ),
          const SizedBox(height: 12),
          _card(
            title: 'How do you feel about strong cooking smells?',
            child: _radioGroup<String>(
              value: strongCookingSmells,
              options: const {
                'ok': 'No problem',
                'sometimes_uncomfortable': 'Sometimes uncomfortable',
                'very_uncomfortable': 'Very uncomfortable',
              },
              onChanged: (v) => setState(() => strongCookingSmells = v),
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (showNoiseFollowups) ...[
          _card(
            title: 'What noise bothers you the most? (select all that apply)',
            child: _chipsMultiSelect(
              options: const {
                'music': 'Music',
                'talking': 'Talking',
                'tv': 'TV',
                'kitchen': 'Kitchen sounds',
              },
              selected: noiseTriggers,
              onToggle: (k) => setState(() {
                if (noiseTriggers.contains(k)) {
                  noiseTriggers.remove(k);
                } else {
                  noiseTriggers.add(k);
                }
              }),
            ),
          ),
        ],
      ],
    );
  }

  // ===== UI helpers =====
  Widget _card({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _sliderInt({
    required int value,
    required int min,
    required int max,
    required String label,
    required void Function(int) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          onChanged: (x) => onChanged(x.round()),
        ),
      ],
    );
  }

  Widget _radioGroup<T>({
    required T? value,
    required Map<T, String> options,
    required void Function(T v) onChanged,
  }) {
    return Column(
      children: options.entries.map((e) {
        return RadioListTile<T>(
          value: e.key,
          groupValue: value,
          title: Text(e.value),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        );
      }).toList(),
    );
  }

  Widget _chipsMultiSelect({
    required Map<String, String> options,
    required Set<String> selected,
    required void Function(String key) onToggle,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((e) {
        final isOn = selected.contains(e.key);
        return FilterChip(
          label: Text(e.value),
          selected: isOn,
          onSelected: (_) => onToggle(e.key),
        );
      }).toList(),
    );
  }
}
