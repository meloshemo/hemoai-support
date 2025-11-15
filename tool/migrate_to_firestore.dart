import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hemoai/firebase_options.dart';
import 'package:hemoai/services/firestore_sync_service.dart' as svc;

/// Simple CLI to migrate local data to Firestore for a given userId.
/// Run from project root with: dart run tool/migrate_to_firestore.dart [userId]
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/migrate_to_firestore.dart [userId]');
    exit(64);
  }
  final userId = int.tryParse(args[0]);
  if (userId == null) {
    stderr.writeln('Invalid userId: ${args[0]}');
    exit(64);
  }
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
    await svc.FirestoreSyncService().migrateLocalToFirestore(userId: userId);
    stdout.writeln('Migration completed for userId=$userId');
    exit(0);
  } catch (e, st) {
    stderr.writeln('Migration failed: $e');
    stderr.writeln(st);
    exit(1);
  }
}
