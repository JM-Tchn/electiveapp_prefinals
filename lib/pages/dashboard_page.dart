import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../student_logo.dart';
import 'account_settings_page.dart';
import 'attendance_page.dart';
import 'grades_page.dart';
import 'student_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  void _selectPage(int index) => setState(() => _selectedIndex = index);

  List<Widget> get _pages => [
    _DashboardHomePage(onNavigate: _selectPage),
    const StudentsPage(),
    const AttendancePage(),
    const GradesPage(),
    const AccountSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wideLayout = constraints.maxWidth >= 900;
        final destinations = [
          const _AppDestination(
            label: 'Home',
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
          ),
          const _AppDestination(
            label: 'Students',
            icon: Icons.people_outline,
            selectedIcon: Icons.people,
          ),
          const _AppDestination(
            label: 'Attendance',
            icon: Icons.event_note_outlined,
            selectedIcon: Icons.event_available,
          ),
          const _AppDestination(
            label: 'Grades',
            icon: Icons.auto_graph_outlined,
            selectedIcon: Icons.auto_graph,
          ),
          const _AppDestination(
            label: 'Account',
            icon: Icons.account_circle_outlined,
            selectedIcon: Icons.account_circle,
          ),
        ];

        return Scaffold(
          body: Row(
            children: [
              if (wideLayout) ...[
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectPage,
                  extended: constraints.maxWidth >= 1200,
                  labelType: constraints.maxWidth >= 1200
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  leading: const Padding(
                    padding: EdgeInsets.only(bottom: 20, top: 12),
                    child: StudentLogo(size: 48),
                  ),
                  destinations: destinations
                      .map(
                        (destination) => NavigationRailDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.selectedIcon),
                          label: Text(destination.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(width: 1, thickness: 1),
              ],
              Expanded(
                child: IndexedStack(index: _selectedIndex, children: _pages),
              ),
            ],
          ),
          bottomNavigationBar: wideLayout
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectPage,
                  destinations: destinations
                      .map(
                        (destination) => NavigationDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.selectedIcon),
                          label: destination.label,
                        ),
                      )
                      .toList(),
                ),
        );
      },
    );
  }
}

class _AppDestination {
  const _AppDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _DashboardHomePage extends StatelessWidget {
  const _DashboardHomePage({required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to open the dashboard.')),
      );
    }

    final students = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('students');
    final displayName = user.displayName?.trim();
    final firstName = displayName != null && displayName.isNotEmpty
        ? displayName.split(' ').first
        : (user.email?.split('@').first ?? 'Admin');
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const StudentLogo(size: 34),
            const SizedBox(width: 10),
            Text(
              'Student Hub',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: students.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load student data: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          final courses = docs
              .map((doc) => doc.data()['course']?.toString().trim() ?? '')
              .where((course) => course.isNotEmpty)
              .toSet()
              .length;
          final studentsByYear = <String, int>{};
          for (final doc in docs) {
            final year = doc.data()['yearLevel']?.toString().trim() ?? '';
            if (year.isNotEmpty) {
              studentsByYear.update(
                year,
                (studentCount) => studentCount + 1,
                ifAbsent: () => 1,
              );
            }
          }
          final yearSummary = studentsByYear.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              _WelcomeCard(
                greeting: greeting,
                firstName: firstName,
                email: user.email ?? '',
              ),
              const SizedBox(height: 24),
              Text(
                'Overview',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _DashboardStatCard(
                          label: 'Total students',
                          value: '${docs.length}',
                          icon: Icons.people_alt_outlined,
                          accent: const Color(0xFF3977B8),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _DashboardStatCard(
                          label: 'Courses',
                          value: '$courses',
                          icon: Icons.menu_book_outlined,
                          accent: const Color(0xFF2A8A89),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Student distribution',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'By year level',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: yearSummary.isEmpty
                      ? const Text('Student year-level data will appear here.')
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: yearSummary
                              .map(
                                (entry) => Chip(
                                  avatar: const Icon(Icons.groups_outlined),
                                  label: Text('${entry.key}: ${entry.value}'),
                                ),
                              )
                              .toList(),
                        ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Quick actions',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 720 ? 3 : 1;
                  final cardWidth =
                      (constraints.maxWidth - (columns - 1) * 12) / columns;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _QuickActionCard(
                          title: 'Manage students',
                          subtitle: 'View, search, or add records',
                          icon: Icons.people_outline,
                          onTap: () => onNavigate(1),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _QuickActionCard(
                          title: 'Take attendance',
                          subtitle: 'Record student presence',
                          icon: Icons.event_available_outlined,
                          onTap: () => onNavigate(2),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _QuickActionCard(
                          title: 'Enter grades',
                          subtitle: 'Track academic progress',
                          icon: Icons.auto_graph_outlined,
                          onTap: () => onNavigate(3),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.greeting,
    required this.firstName,
    required this.email,
  });

  final String greeting;
  final String firstName;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F5A91), Color(0xFF123B66)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24123B66),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: Colors.white.withValues(alpha: 0.82)),
                ),
                const SizedBox(height: 4),
                Text(
                  '$firstName!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  email.isEmpty
                      ? 'Your student information at a glance.'
                      : 'Your academic records are ready to review.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: Colors.white.withValues(alpha: 0.86)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const StudentLogo(size: 68),
        ],
      ),
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.secondaryContainer,
                foregroundColor: colors.onSecondaryContainer,
                child: Icon(icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 15),
            ],
          ),
        ),
      ),
    );
  }
}
