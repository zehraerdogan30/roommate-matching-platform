import '../models/profile.dart';
import 'local/profile_local_ds.dart';

class ProfileRepository {
  final ProfileLocalDataSource local;

  ProfileRepository(this.local);

  Future<void> save(Profile p) => local.save(p);
  Future<Profile?> load() => local.load();
}
