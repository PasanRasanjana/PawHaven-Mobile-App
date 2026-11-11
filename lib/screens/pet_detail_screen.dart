import 'package:url_launcher/url_launcher.dart';

import 'dart:convert';

import 'package:flutter/material.dart';

class PetDetailScreen extends StatelessWidget {
  final Map<String, String> pet;

  const PetDetailScreen({super.key, required this.pet});

  Widget _buildDetailImage(String? base64Str, String? url) {
    if (base64Str != null && base64Str.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(base64Str),
          height: 280,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 280,
            color: Colors.grey.shade300,
            child: const Icon(Icons.pets, size: 80, color: Colors.grey),
          ),
        );
      } catch (_) {}
    }

    return Image.network(
      url?.isNotEmpty == true
          ? url!
          : 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=500',
      height: 280,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        height: 280,
        color: Colors.grey.shade300,
        child: const Icon(Icons.pets, size: 80, color: Colors.grey),
      ),
    );
  }

  Future<void> _openNearbyVets(BuildContext context, String location) async {
    // Search query for veterinary hospitals near that specific location
    final Uri mapUri = Uri.parse(
      'https://www.google.com/maps/search/veterinary+hospital+near+${Uri.encodeComponent(location)}',
    );

    try {
      if (!await launchUrl(mapUri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch Google Maps';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error opening maps: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactNumber = pet['contact']?.isNotEmpty == true
        ? pet['contact']!
        : 'Not provided';
    final description = pet['description']?.isNotEmpty == true
        ? pet['description']!
        : 'No extra description provided for this animal.';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          pet['name'] ?? 'Pet Details',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.teal),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDetailImage(pet['imageBase64'], pet['imageUrl']),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        pet['name']!,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Chip(
                        label: Text(
                          pet['status']!,
                          style: const TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: Colors.teal.shade50,
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pet['breed']!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        pet['location']!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text(
                    'About this Animal',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _openNearbyVets(context, pet['location'] ?? ''),
                    icon: const Icon(Icons.local_hospital, color: Colors.white),
                    label: const Text('Find Nearby Vet Hospitals'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Contact: $contactNumber'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.phone, color: Colors.teal),
                          label: const Text(
                            'Call Carer',
                            style: TextStyle(color: Colors.teal),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.teal),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Adoption / Help request recorded!',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.favorite),
                          label: const Text('Adopt / Help'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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
  }
}
