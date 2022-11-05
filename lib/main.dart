import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import './firebase_options.dart';
import './multi_auth_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const MultiAuth(),
  );
}

class MultiAuth extends StatelessWidget {
  const MultiAuth({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Homepage(),
      title: "MultiAuth",
    );
  }
}

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _phoneNumberController;
  late final StreamSubscription _firebaseStreamEvents;

  @override
  void initState() {
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _phoneNumberController = TextEditingController();

    _firebaseStreamEvents =
        FirebaseAuth.instance.authStateChanges().listen((user) {
      print(user);
      if (user != null) {
        if (user.emailVerified) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const MultiAuthPage(),
            ),
          );
        } else {
          user.sendEmailVerification();
        }
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneNumberController.dispose();
    _firebaseStreamEvents.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Email-password auth"),
      ),
      body: Column(
        children: [
          TextField(
            controller: _emailController,
          ),
          TextField(
            controller: _passwordController,
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final credential = await FirebaseAuth.instance
                    .createUserWithEmailAndPassword(
                        email: _emailController.text.trim(),
                        password: _passwordController.text.trim());
              } on FirebaseAuthException catch (e) {
                if (e.code == "weak-password") {
                  print('The password provided is too weak.');
                } else if (e.code == "email-already-in-use") {
                  print('The account already exists for that email.');
                }
              } catch (e) {
                print(e);
              }
            },
            child: const Text("Submit"),
          ),
          ElevatedButton(
            onPressed: () {
              FirebaseAuth.instance.currentUser!.reload();
              if (FirebaseAuth.instance.currentUser!.emailVerified) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MultiAuthPage(),
                  ),
                );
              }
            },
            child: const Text("Add multifactor auth"),
          ),
        ],
      ),
    );
  }
}
