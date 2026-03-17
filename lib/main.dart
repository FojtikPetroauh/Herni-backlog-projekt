import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/game.dart';
import 'add_game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBp7rlaGNdcV6gueT68NYcnjInXhu88rI0",
      authDomain: "herni-backlog-projekt.firebaseapp.com",
      projectId: "herni-backlog-projekt",
      storageBucket: "herni-backlog-projekt.firebasestorage.app",
      messagingSenderId: "168599336691",
      appId: "1:168599336691:web:a1d001ac1336bb99822986",
    ),
  );

  runApp(const GameBacklogApp());
}

class GameBacklogApp extends StatelessWidget {
  const GameBacklogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Herní Backlog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainListScreen(),
    );
  }
}

class MainListScreen extends StatelessWidget {
  const MainListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CollectionReference gamesRef = FirebaseFirestore.instance.collection('games');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Herní backlog'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: gamesRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Chyba: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('Zatím žádné hry v cloudu.'));
          }

          return ListView.builder(
  itemCount: docs.length,
  itemBuilder: (context, index) {
    var data = docs[index].data() as Map<String, dynamic>;
    final gameId = docs[index].id; 

    return Dismissible(
      key: Key(gameId), 
      
      direction: DismissDirection.endToStart, 
      
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),

      onDismissed: (direction) {
        gamesRef.doc(gameId).delete();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${data['title']} odstraněno')),
        );
      },

      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: ListTile(
          onTap: () {
            final game = Game.fromFirestore(gameId, data);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddGameScreen(gameToEdit: game),
              ),
            );
          },
          leading: const CircleAvatar(child: Icon(Icons.videogame_asset)),
          title: Text(data['title'] ?? 'Bez názvu'),
          subtitle: Text('${data['platform']} • ${data['status']}'),
          trailing: Text('⭐ ${data['rating']}'),
        ),
      ),
    );
  },
);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddGameScreen()),
            );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}