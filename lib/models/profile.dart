class Profile {
  final String id;
  final String city;
  final int budgetMin;
  final int budgetMax;
  final bool smokerOk;
  final int cleanliness;
  final int quietness;
  final int sleepFrom;

  const Profile({
    required this.id,
    required this.city,
    required this.budgetMin,
    required this.budgetMax,
    required this.smokerOk,
    required this.cleanliness,
    required this.quietness,
    required this.sleepFrom,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'city': city,
        'budgetMin': budgetMin,
        'budgetMax': budgetMax,
        'smokerOk': smokerOk,
        'cleanliness': cleanliness,
        'quietness': quietness,
        'sleepFrom': sleepFrom,
      };

  static Profile fromMap(Map<dynamic, dynamic> m) => Profile(
        id: m['id'],
        city: m['city'],
        budgetMin: m['budgetMin'],
        budgetMax: m['budgetMax'],
        smokerOk: m['smokerOk'],
        cleanliness: m['cleanliness'],
        quietness: m['quietness'],
        sleepFrom: m['sleepFrom'],
      );
}
