import 'package:firebase_core/firebase_core.dart';

import 'package:hemoai/config/environment.dart';
// Re-use the FlutterFire generated single-project options for now.
// When you add distinct Firebase projects per environment, replace the
// switch branches with those projects' generated option sets.
import 'package:hemoai/firebase_options.dart' as single_project;

/// Central place to choose FirebaseOptions based on APP_ENV (see Env helper).
///
/// Currently all environments point to the same project. This indirection
/// lets us later introduce distinct dev / staging / prod Firebase projects
/// without touching the rest of the codebase.
class FirebaseOptionsResolver {
  static FirebaseOptions get current {
    final env = Env.value;
    switch (env) {
      case 'prod':
        return single_project.DefaultFirebaseOptions.currentPlatform;
      case 'staging':
        return single_project.DefaultFirebaseOptions.currentPlatform; // TODO: replace with staging project options
      case 'dev':
      default:
        return single_project.DefaultFirebaseOptions.currentPlatform; // TODO: replace with dev project options
    }
  }
}
