import 'package:dockit/presentation/screens/freelancer/add_project.dart';
import 'package:dockit/presentation/screens/freelancer/project_details.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dockit/presentation/screens/profile.dart';

class FreelancerHome extends StatefulWidget {
  const FreelancerHome({super.key});

  @override
  State<FreelancerHome> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<FreelancerHome> {
  int _currentIndex = 0; // Tracks bottom navigation selection

  late final Stream<List<Map<String, dynamic>>> _projectsStream;

  @override
  void initState() {
    super.initState();
    _projectsStream = _watchMyProjects();
  }

  Stream<List<Map<String, dynamic>>> _watchMyProjects() {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
      final email = user?.email?.toLowerCase();
      if (user == null || email == null) return const Stream.empty();

      return FirebaseFirestore.instance
          .collection('projects')
          .doc(email)
          .collection('userProjects')
          .where('ownerId', isEqualTo: user.uid)
          .snapshots()
          .map(
            (s) => s.docs.map((d) {
              final data = d.data();
              return {
                'id': d.id,
                'path': d.reference.path,
                'title': data['name'] as String? ?? '',
                'client': data['clientName'] as String? ?? 'No client yet',
                'description': data['description'] as String? ?? '',
                'status': data['status'] as String? ?? 'active',
                'updatedAt': data['updatedAt'],
                'clientKey': data['clientKey'] as String?,
                'keyExpiresAt': data['keyExpiresAt'],
                'memberLimit': (data['memberLimit'] as num?)?.toInt(),
                'joinedMembers': (data['joinedMembers'] as num?)?.toInt() ?? 0,
                'pendingCount': (data['pendingCount'] as num?)?.toInt() ?? 0,
              };
            }).toList(),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Image.asset(
            //   'assets/images/dockit.png',
            //   height: 22,
            // ),
            // const SizedBox(width: 8),
            const Text(
              'Dockit - Freelancer',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const NewProjectScreen(), // Navigate to the new project screen
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _projectsStream,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Center(
                        child: Text(
                          'Could not load projects\n${snap.error}',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final projects = snap.data!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                              '${projects.length} total',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 4. Project cards
                        Expanded(
                          child: projects.isEmpty
                              ? const Center(child: Text('No projects yet'))
                              : ListView.separated(
                                  itemCount: projects.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final project = projects[index];
                                    final pending =
                                        project['pendingCount'] as int;

                                    return Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7F5F6),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 20,
                                            ),
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ProjectDetailsScreen(
                                                    project: project,
                                                  ),
                                            ),
                                          );
                                        },
                                        title: Text(
                                          project['title'] as String,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          project['client'] as String,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                        trailing: pending > 0
                                            ? Text(
                                                '$pending pending',
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 13,
                                                ),
                                              )
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
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
