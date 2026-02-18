import 'package:flutter/material.dart';
import 'package:flutter_bday/service/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/event_controller.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  int _pendingNotifications = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    final count = await ref.read(eventListProvider.notifier).getPendingNotificationsCount();
    setState(() => _pendingNotifications = count);
  }

  Future<void> _testNotification() async {
    setState(() => _isLoading = true);
    await ref.read(eventListProvider.notifier).testNotification('Test User');
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _rescheduleAll() async {
    setState(() => _isLoading = true);

    final events = ref.read(eventListProvider);
    await NotificationService().rescheduleAllNotifications(events);
    await _loadPendingCount();

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rescheduled $_pendingNotifications notifications'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _cancelAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel All Notifications'),
        content: const Text(
          'Are you sure you want to cancel all scheduled notifications?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      await NotificationService().cancelAllNotifications();
      await _loadPendingCount();
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications cancelled'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventListProvider);
    final activeEvents = events.where((e) => e.isActive).length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats Card
          _buildStatsCard(
            totalEvents: events.length,
            activeEvents: activeEvents,
            pendingNotifications: _pendingNotifications,
          ),
          const SizedBox(height: 20),

          // Notifications Section
          _buildSectionTitle('Notifications'),
          const SizedBox(height: 12),
          _buildActionCard(
            icon: Icons.notification_add,
            title: 'Test Notification',
            subtitle: 'See how birthday reminders will look',
            color: Colors.blue,
            onTap: _testNotification,
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            icon: Icons.refresh,
            title: 'Reschedule All',
            subtitle: 'Refresh all scheduled notifications',
            color: Colors.green,
            onTap: _rescheduleAll,
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            icon: Icons.notifications_off,
            title: 'Cancel All Notifications',
            subtitle: 'Remove all scheduled reminders',
            color: Colors.red,
            onTap: _cancelAll,
          ),
          const SizedBox(height: 20),

          // App Info Section
          _buildSectionTitle('About'),
          const SizedBox(height: 12),
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildStatsCard({
    required int totalEvents,
    required int activeEvents,
    required int pendingNotifications,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.purpleAccent, Colors.pinkAccent],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Statistics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', totalEvents.toString()),
              _buildStatItem('Active', activeEvents.toString()),
              _buildStatItem('Reminders', pendingNotifications.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.purpleAccent, Colors.pinkAccent],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.cake, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Birthday Buddy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Never miss a birthday again! Get reminders at your chosen times and easily connect with your loved ones.',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}