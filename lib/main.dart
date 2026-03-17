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

class GameBacklogApp extends StatefulWidget {
  const GameBacklogApp({super.key});

  @override
  State<GameBacklogApp> createState() => _GameBacklogAppState();
}

class _GameBacklogAppState extends State<GameBacklogApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Herní Backlog',
      debugShowCheckedModeBanner: false,
      
      themeAnimationDuration: Duration.zero, 

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple, 
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple, 
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      
      themeMode: _themeMode,
      home: MainListScreen(onThemeToggle: _toggleTheme, currentMode: _themeMode),
    );
  }
}

class MainListScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final ThemeMode currentMode;

  const MainListScreen({
    super.key, 
    required this.onThemeToggle, 
    required this.currentMode
  });

  @override
  State<MainListScreen> createState() => _MainListScreenState();
}

class _MainListScreenState extends State<MainListScreen> {
  String _selectedStatus = "Vše";
  String _selectedPlatform = "Vše";
  String _selectedRating = "Vše";

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Hraju': return const Color(0xFF66FF00);
      case 'Dohráno': return const Color(0xFF0010EE);
      case 'Chystám se': return const Color(0xFFFFD900);
      case 'Odloženo': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  Widget _buildFilterRow(String label, List<String> options, String currentVal, Function(String) onSelect) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          ...options.map((opt) => Padding(
            padding: const EdgeInsets.only(right: 5),
            child: ChoiceChip(
              label: Text(opt, style: const TextStyle(fontSize: 11)),
              selected: currentVal == opt,
              onSelected: (selected) => onSelect(opt),
            ),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('games');

    if (_selectedStatus != "Vše") {
      query = query.where('status', isEqualTo: _selectedStatus);
    }
    if (_selectedPlatform != "Vše") {
      query = query.where('platform', isEqualTo: _selectedPlatform);
    }
    if (_selectedRating != "Vše") {
      query = query.where('rating', isEqualTo: int.parse(_selectedRating));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Můj Herní Backlog'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(widget.currentMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onThemeToggle,
            tooltip: "Přepnout režim",
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Theme.of(context).brightness == Brightness.light 
                ? Colors.grey.shade100 
                : Colors.grey.shade900,
            child: Column(
              children: [
                _buildFilterRow("Stav", ["Vše", "Chystám se", "Hraju", "Dohráno", "Odloženo"], _selectedStatus, (v) => setState(() => _selectedStatus = v)),
                _buildFilterRow("Platforma", ["Vše", "PC", "Xbox", "PS5", "Switch", "Mobil"], _selectedPlatform, (v) => setState(() => _selectedPlatform = v)),
                _buildFilterRow("Hodnocení", ["Vše", "1", "2", "3", "4", "5"], _selectedRating, (v) => setState(() => _selectedRating = v)),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Chyba: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text('Žádné hry neodpovídají zvoleným filtrům.'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    final gameId = docs[index].id;

                    return Dismissible(
                      key: Key(gameId),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Smazat hru?"),
                            content: const Text("Tato akce trvale odstraní hru z cloudu."),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false), 
                                child: const Text("NE"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true), 
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text("ANO"),
                              ),
                            ],
                          ),
                        );
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        FirebaseFirestore.instance.collection('games').doc(gameId).delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${data['title']} bylo smazáno')),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          onTap: () {
                            final game = Game.fromFirestore(gameId, data);
                            Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (context) => AddGameScreen(gameToEdit: game)),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(data['status'] ?? ''),
                            child: const Icon(Icons.videogame_asset, color: Colors.white),
                          ),
                          title: Text(
                            data['title'] ?? 'Bez názvu', 
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${data['platform']} • ${data['status']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text('${data['rating']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const AddGameScreen()),
          );
        },
        label: const Text('PŘIDAT HRU'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
    );
  }
}