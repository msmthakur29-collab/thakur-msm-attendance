import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ThakurMsmApp());
}

class ThakurMsmApp extends StatelessWidget {
  const ThakurMsmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'THAKUR MSM',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const LoginPage(),
    );
  }
}

// ================= LOGIN =================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  String? error;

  Future<void> login() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final uid = credential.user!.uid;

      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        throw Exception('User profile not found.');
      }

      final data = userDoc.data()!;

      if (data['active'] != true) {
        throw Exception('This account is inactive.');
      }

      final role = data['role'] ?? 'employee';

      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminPage(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const EmployeePage(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        error = e.message ?? 'Login failed.';
      });
    } catch (e) {
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.fingerprint,
                      size: 70,
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      'THAKUR MSM',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Attendance Management System',
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 28),

                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),

                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: loading ? null : login,
                        child: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('LOGIN'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================= EMPLOYEE =================

class EmployeePage extends StatelessWidget {
  const EmployeePage({super.key});

  Future<void> punch(BuildContext context, String type) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final ref =
        FirebaseFirestore.instance.collection('attendance').doc();

    await ref.set({
      'userId': user.uid,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'date': DateTime.now()
          .toIso8601String()
          .substring(0, 10),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            type == 'check_in'
                ? 'Check In saved successfully'
                : 'Check Out saved successfully',
          ),
        ),
      );
    }
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('THAKUR MSM'),
        actions: [
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Employee Dashboard',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            FilledButton.icon(
              onPressed: () => punch(context, 'check_in'),
              icon: const Icon(Icons.login),
              label: const Text('CHECK IN'),
            ),

            const SizedBox(height: 14),

            OutlinedButton.icon(
              onPressed: () => punch(context, 'check_out'),
              icon: const Icon(Icons.logout),
              label: const Text('CHECK OUT'),
            ),

            const SizedBox(height: 30),

            const Text(
              'Your attendance is stored securely in Firebase.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ================= ADMIN =================

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('THAKUR MSM • ADMIN'),
        actions: [
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendance')
            .orderBy('timestamp', descending: true)
            .limit(100)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error: ${snapshot.error}',
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No attendance records yet.',
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Attendance Records',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              ...docs.map((doc) {
                final data =
                    doc.data() as Map<String, dynamic>;

                final type = data['type'] ?? '';
                final userId = data['userId'] ?? '-';
                final date = data['date'] ?? '-';

                final isCheckIn = type == 'check_in';

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        isCheckIn
                            ? Icons.login
                            : Icons.logout,
                      ),
                    ),
                    title: Text(
                      isCheckIn ? 'Check In' : 'Check Out',
                    ),
                    subtitle: Text(
                      'User: $userId\nDate: $date',
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
