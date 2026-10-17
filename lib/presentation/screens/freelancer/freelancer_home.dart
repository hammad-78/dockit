import 'package:flutter/material.dart';

import '../profile.dart';

class FreelancerHome extends StatefulWidget {
  const FreelancerHome({super.key});

  @override
  State<FreelancerHome> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<FreelancerHome> {
  int _currentIndex = 0; // Tracks bottom navigation selection

  // --- PLACEHOLDERS FOR YOUR REAL DATA ---
  // Replace these lists with data fetched from your backend API or State Management
  final List<Map<String, dynamic>> projects = [
    {'title': 'Nova Cafe Branding', 'client': 'Ali Raza', 'pendingCount': 2},
    {'title': 'Mobile App Design', 'client': 'Hina Tariq', 'pendingCount': 0},
    {'title': 'Website Copy', 'client': 'Usman Sheikh', 'pendingCount': 1},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Profile Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Freelancer Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(
                      0xFF0A2540,
                    ), // Deep blue profile icon bg
                    child: const Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),

                ],
              ),
              const SizedBox(height: 16),

              // 2. Title Row (Projects + Add Button)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Projects',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F4F5), // Light gray square
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.add,
                        color: Colors.black,
                        size: 24,
                      ),
                      onPressed: () {
                        // TODO: Add your create project logic here
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Subtitle Counter Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Deliverables',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    '${projects.length} total', // Dynamic counter based on list length
                    style: const TextStyle(fontSize: 14, color: Colors.black45),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 4. Dynamic Project Cards List
              Expanded(
                child: ListView.separated(
                  itemCount: projects.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    final int pending = project['pendingCount'];

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(51), // 0.02 * 255 = 51
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left side: Text Details
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project['title'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                project['client'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                          // Right side: Pending Indicators
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  // Gray indicator if 0 pending, otherwise darker gray/black
                                  color: pending > 0
                                      ? Colors.black54
                                      : Colors.black26,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$pending pending',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: pending > 0
                                      ? Colors.black54
                                      : Colors.black26,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // 5. Client Agreement Vault Footer Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFF7F5F6,
                  ), // Soft warm grayish/pink background
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2.0),
                      child: Icon(
                        Icons.shield_outlined,
                        color: Colors.black54,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Client Agreement Vault',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'All milestone agreements are sealed and immutable under current contract records.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),

      // 6. Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            return;
          }
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black87,
        unselectedItemColor: Colors.black38,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_open_outlined, size: 26),
            activeIcon: Icon(Icons.folder_open, size: 26),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 26),
            activeIcon: Icon(Icons.person, size: 26),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
