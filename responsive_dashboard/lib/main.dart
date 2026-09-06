import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const AcademicOverviewApp());
}

class AcademicOverviewApp extends StatefulWidget {
  const AcademicOverviewApp({super.key});

  @override
  State<AcademicOverviewApp> createState() => _AcademicOverviewAppState();
}

class _AcademicOverviewAppState extends State<AcademicOverviewApp> {
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Academic Overview',

      // Light Theme
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.indigo,
      ),

      // Dark Theme
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.indigo,
      ),

      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

      home: AcademicOverviewPage(
        isDark: isDark,
        onThemeChanged: (value) {
          setState(() {
            isDark = value;
          });
        },
      ),
    );
  }
}

class AcademicOverviewPage extends StatelessWidget {
  const AcademicOverviewPage({
    required this.isDark,
    required this.onThemeChanged,
    super.key,
  });

  final bool isDark;
  final ValueChanged<bool> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Overview'),

        actions: [
          Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
          ),

          const SizedBox(width: 8),

          CupertinoSwitch(
            value: isDark,
            onChanged: onThemeChanged,
          ),

          const SizedBox(width: 16),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // =========================
            // HEADER PROFIL
            // =========================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),

              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: theme.colorScheme.primary,
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Qulbi Khutsi Azzumi',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '244107020050',
                          style: theme.textTheme.bodyMedium,
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'D-IV Teknik Informatika',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Academic Summary',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // =========================
            // RESPONSIVE CARDS
            // =========================

            LayoutBuilder(
              builder: (context, constraints) {

                // Responsive breakpoint
                final columns =
                    constraints.maxWidth >= 700 ? 2 : 1;

                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),

                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,

                  childAspectRatio: columns == 2 ? 2.5 : 3,

                  children: const [
                    AcademicCard(
                      icon: Icons.assignment,
                      title: 'Assignments',
                      value: '8',
                      subtitle: 'Pending tasks',
                    ),

                    AcademicCard(
                      icon: Icons.check_circle,
                      title: 'Attendance',
                      value: '92%',
                      subtitle: 'This semester',
                    ),

                    AcademicCard(
                      icon: Icons.star,
                      title: 'GPA',
                      value: '3.85',
                      subtitle: 'Current GPA',
                    ),

                    AcademicCard(
                      icon: Icons.calendar_month,
                      title: 'Current Week',
                      value: '02',
                      subtitle: 'Mobile Development',
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // =========================
            // ADDITIONAL INFORMATION
            // =========================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Academic Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Row(
                    children: [
                      Expanded(
                        child: Text('Semester'),
                      ),
                      Text('5'),
                    ],
                  ),

                  const Divider(),

                  const Row(
                    children: [
                      Expanded(
                        child: Text('Program'),
                      ),
                      Text('D-IV Teknik Informatika'),
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

// =========================
// ACADEMIC CARD
// =========================

class AcademicCard extends StatelessWidget {
  const AcademicCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),

      child: Row(
        children: [

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.onPrimary,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),

          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}