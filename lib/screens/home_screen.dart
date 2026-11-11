import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'add_pet_screen.dart';
import 'pet_detail_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filterCategories = [
    'All',
    'Stray / Rescue',
    'Lost Pet',
    'For Adoption',
  ];

  static const Color bgColor = Color(0xFFFCECD7);
  static const Color primaryOrange = Color(0xFFD46211);
  static const Color textDark = Color(0xFF26160C);

  Widget _buildPetImage(String? base64Str, String? url) {
    if (base64Str != null && base64Str.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(base64Str),
          height: 190,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 190,
            color: const Color(0xFFEAD2BE),
            child: const Icon(Icons.pets, size: 50, color: Color(0xFF8A6A53)),
          ),
        );
      } catch (_) {}
    }

    return Image.network(
      url?.isNotEmpty == true
          ? url!
          : 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=500',
      height: 190,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        height: 190,
        color: const Color(0xFFEAD2BE),
        child: const Icon(Icons.pets, size: 50, color: Color(0xFF8A6A53)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('pets');

    if (_selectedCategory != 'All') {
      query = query.where('status', isEqualTo: _selectedCategory);
    }
    query = query.orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Icon(Icons.pets, color: textDark, size: 28),
        ),
        title: const Text(
          'PAWLY',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: textDark,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: textDark),
            tooltip: 'Log Out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Tagline from Figma
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Small acts.',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                    height: 1.1,
                  ),
                ),
                Text(
                  'Second chances.',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() => _searchQuery = val.trim().toLowerCase());
              },
              decoration: InputDecoration(
                hintText: 'Search a name, breed, or location...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Colors.brown.shade400,
                ),
                prefixIcon: const Icon(Icons.search, color: textDark),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Filter Chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _filterCategories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _filterCategories[index];
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: primaryOrange,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.brown.shade800,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: isSelected ? primaryOrange : const Color(0xFFE8D3BF),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = category);
                    }
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // Pet Cards Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryOrange),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final petDocs = snapshot.data?.docs ?? [];

                final filteredDocs = petDocs.where((doc) {
                  if (_searchQuery.isEmpty) return true;
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final breed = (data['breed'] ?? '').toString().toLowerCase();
                  final location = (data['location'] ?? '')
                      .toString()
                      .toLowerCase();

                  return name.contains(_searchQuery) ||
                      breed.contains(_searchQuery) ||
                      location.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No animals found in this category.',
                      style: TextStyle(
                        color: Color(0xFF8A6A53),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data =
                        filteredDocs[index].data() as Map<String, dynamic>;

                    final petMap = {
                      'name': (data['name'] ?? 'Unnamed').toString(),
                      'breed': (data['breed'] ?? 'Unknown').toString(),
                      'status': (data['status'] ?? 'Rescue').toString(),
                      'location': (data['location'] ?? 'Unknown').toString(),
                      'imageUrl': (data['imageUrl'] ?? '').toString(),
                      'imageBase64': (data['imageBase64'] ?? '').toString(),
                      'contact': (data['contact'] ?? '').toString(),
                      'description': (data['description'] ?? '').toString(),
                    };

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PetDetailScreen(pet: petMap),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                              child: _buildPetImage(
                                petMap['imageBase64'],
                                petMap['imageUrl'],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          petMap['name']!,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: textDark,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFDEFD9),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          petMap['status']!,
                                          style: const TextStyle(
                                            color: primaryOrange,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    petMap['breed']!,
                                    style: TextStyle(
                                      color: Colors.brown.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: primaryOrange,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          petMap['location']!,
                                          style: TextStyle(
                                            color: Colors.brown.shade700,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
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
            MaterialPageRoute(builder: (context) => const AddPetScreen()),
          );
        },
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo),
        label: const Text(
          'Post Animal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
