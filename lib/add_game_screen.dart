import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/game.dart';

class AddGameScreen extends StatefulWidget {
  final Game? gameToEdit;
  const AddGameScreen({super.key, this.gameToEdit});

  @override
  State<AddGameScreen> createState() => _AddGameScreenState();
}

class _AddGameScreenState extends State<AddGameScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _platform;
  late String _status;
  late int _rating;

  @override
  void initState() {
    super.initState();
    _title = widget.gameToEdit?.title ?? '';
    _platform = widget.gameToEdit?.platform ?? 'PC';
    _status = widget.gameToEdit?.status ?? 'Chystám se';
    _rating = widget.gameToEdit?.rating ?? 3;
  }

  Future<void> _saveToFirebase() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final db = FirebaseFirestore.instance.collection('games');
      final data = {
        'title': _title,
        'platform': _platform,
        'status': _status,
        'rating': _rating,
      };

      if (widget.gameToEdit == null) {
        await db.add(data);
      } else {
        await db.doc(widget.gameToEdit!.id).update(data);
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.gameToEdit == null ? 'Přidat hru' : 'Upravit hru')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(labelText: 'Název hry', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Tohle pole nesmí být prázdné' : null,
                onSaved: (v) => _title = v!,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _platform,
                decoration: const InputDecoration(labelText: 'Platforma'),
                items: ['PC', 'PS5', 'Xbox', 'Switch', 'Mobil'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => _platform = v!),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Stav'),
                items: ['Chystám se', 'Hraju', 'Dohráno', 'Odloženo'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 20),
              Text('Hodnocení: $_rating ⭐'),
              Slider(
                value: _rating.toDouble(), min: 1, max: 5, divisions: 4,
                onChanged: (v) => setState(() => _rating = v.toInt()),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveToFirebase,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('ULOŽIT DO CLOUDU'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}