import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';

class RecentSeedsSection extends StatelessWidget {
  final List<LifeEntity> seeds;
  final VoidCallback? onRefresh;

  const RecentSeedsSection({
    super.key,
    required this.seeds,
    this.onRefresh,
  });

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return 'Poco fa';
    } else if (difference.inHours < 24 && date.day == now.day) {
      return 'Oggi';
    } else if (difference.inDays < 2) {
      return 'Ieri';
    } else {
      return '${difference.inDays} giorni fa';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.eco_rounded, color: Color(0xFF10B981), size: 18),
            const SizedBox(width: 8),
            const Text(
              'Semi Recenti',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${seeds.length}',
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const Spacer(),
            if (onRefresh != null)
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white38, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onRefresh,
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (seeds.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: const Row(
              children: [
                Icon(Icons.inbox_outlined, color: Colors.white30, size: 28),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Nessun seme in attesa.\nUsa la barra di cattura per appuntare idee grezze senza dover decidere subito cosa siano.',
                    style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: seeds.length > 5 ? 5 : seeds.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final seed = seeds[index];
              return InkWell(
                onTap: () {
                  context.push('/life_os/entity/${seed.id}', extra: seed);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              seed.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (seed.description != null && seed.description!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                seed.description!,
                                style: const TextStyle(color: Colors.white38, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatRelativeDate(seed.createdAt),
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 18),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
