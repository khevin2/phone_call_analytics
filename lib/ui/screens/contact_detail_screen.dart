import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/call_record.dart';

class ContactDetailScreen extends StatelessWidget {
  const ContactDetailScreen({
    super.key,
    required this.number,
    required this.name,
    required this.calls,
  });

  final String number;
  final String? name;
  final List<CallRecord> calls;

  @override
  Widget build(BuildContext context) {
    // Sort calls by timestamp descending (most recent first)
    final sortedCalls = List<CallRecord>.from(calls)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Find the longest call
    final longestCall = sortedCalls.reduce(
      (a, b) => a.durationSec > b.durationSec ? a : b,
    );

    // Calculate total duration
    final totalDuration = calls.fold<int>(
      0,
      (sum, call) => sum + call.durationSec,
    );

    final dateFormatter = DateFormat('MMM d, yyyy');
    final timeFormatter = DateFormat('h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(name?.isNotEmpty == true ? name! : number),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        child: Text(
                          (name?.isNotEmpty == true ? name! : number)
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name?.isNotEmpty == true ? name! : number,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (name?.isNotEmpty == true)
                              Text(
                                number,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey,
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: 'Total Calls',
                        value: '${calls.length}',
                        icon: Icons.call,
                      ),
                      _StatItem(
                        label: 'Total Time',
                        value: _formatDuration(totalDuration),
                        icon: Icons.timer_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Longest call highlight
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Longest Call',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatDuration(longestCall.durationSec)} on ${dateFormatter.format(longestCall.timestamp)} at ${timeFormatter.format(longestCall.timestamp)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Call history header
          Text(
            'Call History',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          // Call history list
          ...sortedCalls.map((call) {
            final isLongest = call.callId == longestCall.callId;
            return Card(
              child: ListTile(
                leading: _CallTypeIcon(type: call.type),
                title: Row(
                  children: [
                    Text(
                      '${dateFormatter.format(call.timestamp)} at ${timeFormatter.format(call.timestamp)}',
                    ),
                    if (isLongest) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  '${_callTypeLabel(call.type)} · ${_formatDuration(call.durationSec)}',
                ),
                trailing: isLongest
                    ? Chip(
                        label: const Text('Longest'),
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontSize: 12,
                        ),
                      )
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return '0 sec';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  String _callTypeLabel(CallType type) {
    return switch (type) {
      CallType.incoming => 'Incoming',
      CallType.outgoing => 'Outgoing',
      CallType.missed => 'Missed',
      CallType.rejected => 'Rejected',
      CallType.unknown => 'Unknown',
    };
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
      ],
    );
  }
}

class _CallTypeIcon extends StatelessWidget {
  const _CallTypeIcon({required this.type});

  final CallType type;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      CallType.incoming => (Icons.call_received, Colors.green),
      CallType.outgoing => (Icons.call_made, Colors.blue),
      CallType.missed => (Icons.call_missed, Colors.red),
      CallType.rejected => (Icons.call_end, Colors.orange),
      CallType.unknown => (Icons.call, Colors.grey),
    };

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color),
    );
  }
}
