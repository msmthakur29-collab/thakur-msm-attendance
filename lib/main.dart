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
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'THAKUR MSM',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
        home: const LoginPage(),
      );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  String? error;
  Future<void> login() async {
    setState(() { loading = true; error = null; });
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(), password: password.text,
      );
      final doc = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
      if (!doc.exists || doc.data()?['active'] != true) throw Exception('Account inactive or profile missing.');
      final role = doc.data()?['role'] ?? 'employee';
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => role == 'admin' ? const AdminPage() : const EmployeePage()));
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message ?? 'Login failed');
    } catch (e) { setState(() => error = e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => loading = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 430), child: Card(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Icon(Icons.fingerprint, size: 64), const SizedBox(height: 12), const Text('THAKUR MSM', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)), const Text('Attendance Management System', textAlign: TextAlign.center), const SizedBox(height: 28),
    TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email))), const SizedBox(height: 12),
    TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock))), const SizedBox(height: 20),
    if (error != null) Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)), const SizedBox(height: 8),
    FilledButton(onPressed: loading ? null : login, child: loading ? const CircularProgressIndicator() : const Text('LOGIN')),
  ]))))));
}

class EmployeePage extends StatelessWidget { const EmployeePage({super.key});
  Future<void> punch(BuildContext context, String type) async {
    final u = FirebaseAuth.instance.currentUser!; final ref = FirebaseFirestore.instance.collection('attendance').doc();
    await ref.set({'userId': u.uid, 'type': type, 'timestamp': FieldValue.serverTimestamp(), 'date': DateTime.now().toIso8601String().substring(0,10)});
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$type saved')));
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('THAKUR MSM')), body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [const Text('Employee Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 24), Row(children: [Expanded(child: FilledButton.icon(onPressed: () => punch(context,'check_in'), icon: const Icon(Icons.login), label: const Text('CHECK IN'))), const SizedBox(width: 12), Expanded(child: OutlinedButton.icon(onPressed: () => punch(context,'check_out'), icon: const Icon(Icons.logout), label: const Text('CHECK OUT')))]), const SizedBox(height: 24), const Text('Attendance records are stored centrally in Firebase.')]));
}

class AdminPage extends StatelessWidget { const AdminPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('THAKUR MSM • ADMIN'), actions: [IconButton(onPressed: () async { await FirebaseAuth.instance.signOut(); if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false); }, icon: const Icon(Icons.logout))]), body: StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('attendance').orderBy('timestamp', descending: true).limit(100).snapshots(), builder: (context,s){ if(s.hasError) return Center(child: Text('Error: ${s.error}')); if(!s.hasData) return const Center(child: CircularProgressIndicator()); final docs=s.data!.docs; return ListView(padding: const EdgeInsets.all(16), children:[const Text('Attendance Records',style: TextStyle(fontSize:24,fontWeight:FontWeight.bold)),const SizedBox(height:12),...docs.map((d){final x=d.data() as Map<String,dynamic>; return Card(child: ListTile(leading: Icon(x['type']=='check_in'?Icons.login:Icons.logout),title: Text(x['type']=='check_in'?'Check In':'Check Out'),subtitle: Text('User: ${x['userId']}\nDate: ${x['date'] ?? '-'}'));})]); })); }
}
