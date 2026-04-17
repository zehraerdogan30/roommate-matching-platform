import 'package:hive/hive.dart';
import '../../models/profile.dart';

class ProfileLocalDataSource {
  static const _boxName = 'profileBox';
  static const _key = 'myProfile';

  Future<Box> _open() async => Hive.openBox(_boxName);

  Future<void> save(Profile p) async {
    final box = await _open();
    await box.put(_key, p.toMap());
  }

  Future<Profile?> load() async {
    final box = await _open();
    final data = box.get(_key);
    if (data == null) return null;
    return Profile.fromMap(Map<dynamic, dynamic>.from(data));
  }
}
