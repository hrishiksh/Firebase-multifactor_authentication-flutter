import "package:flutter/material.dart";
import 'package:firebase_auth/firebase_auth.dart';

class MultiAuthPage extends StatefulWidget {
  const MultiAuthPage({super.key});

  @override
  State<MultiAuthPage> createState() => _MultiAuthPageState();
}

class _MultiAuthPageState extends State<MultiAuthPage> {
  late final TextEditingController _phoneNumberController;

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    _phoneNumberController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
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
            controller: _phoneNumberController,
          ),
          ElevatedButton(
            onPressed: () async {
              MultiFactorSession session = await user!.multiFactor.getSession();
              final auth = FirebaseAuth.instance;
              await auth.verifyPhoneNumber(
                multiFactorSession: session,
                phoneNumber: _phoneNumberController.text.trim(),
                verificationCompleted: (_) {},
                verificationFailed: (_) {},
                codeSent: (String varificationID, int? resendToken) async {
                  String? smsCode = await getSmsCodeFromUser(context);
                  if (smsCode != null) {
                    final credential = PhoneAuthProvider.credential(
                      verificationId: varificationID,
                      smsCode: smsCode,
                    );
                    try {
                      await user!.multiFactor.enroll(
                          PhoneMultiFactorGenerator.getAssertion(credential));
                    } catch (e) {
                      print(e);
                    }
                  }
                },
                codeAutoRetrievalTimeout: (_) {},
              );
            },
            child: const Text("Submit"),
          ),
          ElevatedButton(
              onPressed: () async {
                print(
                  await user!.multiFactor.getEnrolledFactors(),
                );
              },
              child: const Text("Multifactor check"))
        ],
      ),
    );
  }
}
