import 'package:flutter/material.dart';

class User {
  final String username;
  final String name;
  final String surname;
  final String email;

  User({
    required this.username,
    required this.name,
    required this.surname,
    required this.email,
  });
}

class ProfilPage extends StatelessWidget {
  final User user;
  const ProfilPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 60),
          ),
          const SizedBox(height: 30),
          _profileInfoCard('Kullanıcı Adı', user.username),
          const SizedBox(height: 15),
          _profileInfoCard('Ad', user.name),
          const SizedBox(height: 15),
          _profileInfoCard('Soyad', user.surname),
          const SizedBox(height: 15),
          _profileInfoCard('Email', user.email),
        ],
      ),
    );
  }

  Widget _profileInfoCard(String label, String value) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          children: [
            Text(
              '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
