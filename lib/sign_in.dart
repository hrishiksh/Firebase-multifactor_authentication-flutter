import 'package:firebase_core/firebase_core.dart';
import "package:flutter/material.dart";
import 'package:firebase_auth/firebase_auth.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<String?> getSmsCodeFromUser(BuildContext context) async {
    String? smsCode;

    // Update the UI - wait for the user to enter the SMS code
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('SMS code:'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Sign in'),
            ),
            OutlinedButton(
              onPressed: () {
                smsCode = null;
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
          content: Container(
            padding: const EdgeInsets.all(20),
            child: TextField(
              onChanged: (value) {
                smsCode = value;
              },
              textAlign: TextAlign.center,
              autofocus: true,
            ),
          ),
        );
      },
    );

    return smsCode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Multi auth page"),
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
                await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: _emailController.text,
                  password: _passwordController.text,
                );
              } on FirebaseAuthMultiFactorException catch (e) {
                final resolver = e.resolver;
                final session = resolver.session;
                await FirebaseAuth.instance.verifyPhoneNumber(
                  multiFactorSession: session,
                  verificationCompleted: (_) {},
                  verificationFailed: (_) {},
                  codeSent: (String verificationId, int? resendToken) async {
                    final smsCode = await getSmsCodeFromUser(context);
                    if (smsCode != null) {
                      final credential = PhoneAuthProvider.credential(
                        verificationId: verificationId,
                        smsCode: smsCode,
                      );
                      try {
                        await e.resolver.resolveSignIn(
                            PhoneMultiFactorGenerator.getAssertion(credential));
                      } on FirebaseAuthException catch (e) {
                        print(e.message);
                      }
                    }
                  },
                  codeAutoRetrievalTimeout: (_) {},
                );
              }
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }
}
