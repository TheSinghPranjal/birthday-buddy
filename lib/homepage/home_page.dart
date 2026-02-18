import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/event_controller.dart';
import '../widgets/custom_components/custom_event_card.dart';
import 'event_form.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int? _selectedMonth;

  final List<String> _monthNames = [
    'All',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  Future<void> _addEvent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EventForm()),
    );

    if (result != null && result is Map) {
      await ref.read(eventListProvider.notifier).addEvent(result['event']);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Birthday added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventListProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.purpleAccent, Colors.pinkAccent],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.cake,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Birthday Buddy',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_selectedMonth != null)
            IconButton(
              onPressed: () {
                setState(() => _selectedMonth = null);
                ref.read(eventListProvider.notifier).clearFilters();
              },
              icon: const Icon(Icons.clear),
              color: Colors.black87,
              tooltip: 'Clear filter',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search birthdays...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, color: Colors.purpleAccent.shade200),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.purpleAccent, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                ref.read(eventListProvider.notifier).searchEvents(value);
              },
            ),
          ),

          // Month Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _monthNames.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedMonth == index;
                  final isAll = index == 0;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_monthNames[index]),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedMonth = selected ? index : null;
                        });
                        if (isAll || !selected) {
                          ref.read(eventListProvider.notifier).clearFilters();
                        } else {
                          ref.read(eventListProvider.notifier).filterByMonth(index);
                        }
                      },
                      selectedColor: Colors.purpleAccent.shade100,
                      checkmarkColor: Colors.purpleAccent,
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.purpleAccent.shade700 : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.purpleAccent
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Event List
          Expanded(
            child: events.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cake_outlined,
                      size: 80,
                      color: Colors.purpleAccent.shade200,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No birthdays yet',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first birthday',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return CustomEventCard(
                  event: event,
                  index: index,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEvent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Birthday',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 8,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
        extendedIconLabelSpacing: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        // Gradient background
        foregroundColor: Colors.white,
      ).decoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.purpleAccent, Colors.pinkAccent],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.purpleAccent.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
      ),
    );
  }
}

// Extension to add gradient decoration to FAB
extension DecoratedWidget on Widget {
  Widget decoratedBox({required BoxDecoration decoration}) {
    return Container(
      decoration: decoration,
      child: this,
    );
  }
}