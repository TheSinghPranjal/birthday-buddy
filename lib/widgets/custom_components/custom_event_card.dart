import 'package:flutter/material.dart';
import 'package:flutter_bday/homepage/event_form.dart';
import 'package:flutter_bday/models/event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../controllers/event_controller.dart';

class CustomEventCard extends ConsumerWidget {
  final BirthdayEvent event;
  final int index;

  const CustomEventCard({
    super.key,
    required this.event,
    required this.index,
  });

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    // Remove any spaces or special characters
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri launchUri = Uri.parse('https://wa.me/$cleanNumber');

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysLeft = event.daysUntilBirthday();
    final age = event.getAge();

    return Dismissible(
      key: ValueKey('${event.name}-${event.birthday.toIso8601String()}-$index'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await ref.read(eventListProvider.notifier).toggleEvent(index);
        final status = event.isActive ? 'deactivated' : 'activated';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${event.name}\'s birthday $status'),
            backgroundColor: event.isActive ? Colors.orange : Colors.green,
          ),
        );
        return false;
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: event.isActive
                ? [Colors.orange.shade400, Colors.orange.shade600]
                : [Colors.green.shade400, Colors.green.shade600],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              event.isActive ? Icons.notifications_off : Icons
                  .notifications_active,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              event.isActive ? 'Mute' : 'Unmute',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.purple.shade50.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.shade100.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventForm(event: event, index: index),
                  ),
                );

                if (result != null && result is Map) {
                  await ref.read(eventListProvider.notifier).updateEvent(
                    result['index'] ?? index,
                    result['event'],
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Birthday updated!')),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Profile Image
                    Hero(
                      tag: 'profile-$index',
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Colors.purpleAccent, Colors.pinkAccent],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purpleAccent.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: event.profileImagePath != null
                            ? ClipOval(
                          child: Image.file(
                            File(event.profileImagePath!),
                            fit: BoxFit.cover,
                          ),
                        )
                            : Center(
                          child: Text(
                            event.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Event Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  event.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: event.isActive
                                      ? Colors.green.shade100
                                      : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      event.isActive
                                          ? Icons.notifications_active
                                          : Icons.notifications_off,
                                      size: 14,
                                      color: event.isActive
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${event.birthday.day}/${event.birthday
                                .month}/${event.birthday.year}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.cake,
                                size: 16,
                                color: Colors.purpleAccent.shade200,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                daysLeft == 0
                                    ? '🎉 Today! Turning $age'
                                    : daysLeft == 1
                                    ? '🎂 Tomorrow! Turning $age'
                                    : '$daysLeft days left • Turning $age',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: daysLeft <= 7
                                      ? Colors.orange.shade700
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          if (event.reminderTimes.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.alarm,
                                  size: 16,
                                  color: Colors.blue.shade400,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${event.reminderTimes.length} reminder${event
                                      .reminderTimes.length > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Action Buttons
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (event.contactNumber != null) ...[
                          IconButton(
                            onPressed: () =>
                                _makePhoneCall(event.contactNumber!),
                            icon: const Icon(Icons.phone),
                            color: Colors.green.shade600,
                            tooltip: 'Call',
                            iconSize: 22,
                          ),
                          IconButton(
                            onPressed: () =>
                                _openWhatsApp(event.contactNumber!),
                            icon: const Icon(Icons.message),
                            color: Colors.green.shade700,
                            tooltip: 'WhatsApp',
                            iconSize: 22,
                          ),
                        ],
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                          onSelected: (value) async {
                            if (value == 'edit') {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EventForm(
                                        event: event,
                                        index: index,
                                      ),
                                ),
                              );

                              if (result != null && result is Map) {
                                await ref
                                    .read(eventListProvider.notifier)
                                    .updateEvent(
                                  result['index'] ?? index,
                                  result['event'],
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Birthday updated!')),
                                );
                              }
                            } else if (value == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) =>
                                    AlertDialog(
                                      title: const Text('Delete Birthday'),
                                      content: Text(
                                        'Are you sure you want to delete ${event
                                            .name}\'s birthday?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                              );

                              if (confirm == true) {
                                await ref
                                    .read(eventListProvider.notifier)
                                    .deleteEvent(index);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${event.name}\'s birthday deleted'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          itemBuilder: (context) =>
                          const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 12),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20,
                                      color: Colors.red),
                                  SizedBox(width: 12),
                                  Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}