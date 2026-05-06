import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/todo_provider.dart';
import '../utils/constants.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<TodoProvider>().fetchStats(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 20,
        toolbarHeight: 72,
        title: const Text(
          'Stats',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            height: 1.1,
          ),
        ),
      ),
      body: Consumer<TodoProvider>(
        builder: (context, provider, _) {
          final stats = provider.stats;
          if (stats == null) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }

          final total = _asInt(stats['total']);
          final completed = _asInt(stats['completed']);
          final pending = _asInt(stats['pending']);
          final overdue = _asInt(stats['overdue']);
          final byPriority = (stats['by_priority'] as Map?) ?? const {};
          final high = _asInt(byPriority['high']);
          final medium = _asInt(byPriority['medium']);
          final low = _asInt(byPriority['low']);

          return RefreshIndicator(
            color: Colors.black,
            onRefresh: () => context.read<TodoProvider>().fetchStats(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.25,
                  children: [
                    _StatCard(
                      label: 'Total tasks',
                      value: total,
                      color: const Color(0xFF2563EB),
                      background: const Color(0xFFEFF4FF),
                    ),
                    _StatCard(
                      label: 'Completed',
                      value: completed,
                      color: const Color(0xFF16A34A),
                      background: const Color(0xFFEAF8EE),
                    ),
                    _StatCard(
                      label: 'Pending',
                      value: pending,
                      color: const Color(0xFFEA580C),
                      background: const Color(0xFFFDF1E7),
                    ),
                    _StatCard(
                      label: 'Overdue',
                      value: overdue,
                      color: const Color(0xFFDC2626),
                      background: const Color(0xFFFDECEC),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  'By priority',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                _PriorityRow(
                  label: 'High',
                  count: high,
                  total: total,
                  color: priorityColors[Priority.high]!,
                ),
                const SizedBox(height: 10),
                _PriorityRow(
                  label: 'Medium',
                  count: medium,
                  total: total,
                  color: priorityColors[Priority.medium]!,
                ),
                const SizedBox(height: 10),
                _PriorityRow(
                  label: 'Low',
                  count: low,
                  total: total,
                  color: priorityColors[Priority.low]!,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  final String label;
  final int value;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.0,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityRow extends StatelessWidget {
  const _PriorityRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(height: 8, color: const Color(0xFFF2F2F2)),
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(height: 8, color: color),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 32,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
