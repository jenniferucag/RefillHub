import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_controller.dart';

class RefillHubApp extends StatefulWidget {
  const RefillHubApp({super.key});

  @override
  State<RefillHubApp> createState() => _RefillHubAppState();
}

class _RefillHubAppState extends State<RefillHubApp> {
  late final AuthController auth = AuthController(
    FirebaseAuthBackend(FirebaseAuth.instance, FirebaseFirestore.instance),
  );
  late final GoRouter router = createAppRouter(auth: auth);

  @override
  void dispose() {
    router.dispose();
    auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: auth,
      child: MaterialApp.router(
        title: 'RefillHub',
        theme: appTheme,
        routerConfig: router,
      ),
    );
  }
}
