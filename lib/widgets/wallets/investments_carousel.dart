import 'package:flutter/material.dart';
import 'package:solducci/features/investments/views/investments_hub_view.dart';
import 'package:solducci/models/investment_portfolio.dart';
import 'package:solducci/service/investment_asset_service.dart';
import 'package:solducci/service/investment_portfolio_service.dart';

class InvestmentsCarousel extends StatefulWidget {
  const InvestmentsCarousel({super.key});

  @override
  State<InvestmentsCarousel> createState() => _InvestmentsCarouselState();
}

class _InvestmentsCarouselState extends State<InvestmentsCarousel> {
  final _portfolioService = InvestmentPortfolioService();
  List<InvestmentPortfolio> _portfolios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _portfolioService.addListener(_onServiceUpdate);
    _loadPortfolios();
  }

  @override
  void dispose() {
    _portfolioService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) {
      setState(() {
        _portfolios = _portfolioService.currentPortfolios;
      });
    }
  }

  Future<void> _loadPortfolios() async {
    final list = await _portfolioService.fetchPortfolios();
    if (mounted) {
      setState(() {
        _portfolios = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 110,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF818CF8)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Intestazione
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.trending_up_rounded, size: 18, color: Color(0xFF818CF8)),
                  SizedBox(width: 8),
                  Text(
                    'I miei asset di investimento',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => const InvestmentsHubView()),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Text('Gestisci', style: TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF818CF8)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Carosello
        SizedBox(
          height: 104,
          child: _portfolios.isEmpty
              ? _buildEmptyPortfolios(context)
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _portfolios.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    if (index == _portfolios.length) {
                      // Bottone Aggiungi in coda
                      return _buildAddPortfolioCard(context);
                    }

                    final p = _portfolios[index];
                    final assets = InvestmentAssetService().getAssetsForPortfolio(p.id);
                    final val = assets.fold(0.0, (sum, a) => sum + a.currentValue);

                    return _buildPortfolioCard(context, p, val);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPortfolioCard(BuildContext context, InvestmentPortfolio p, double value) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (ctx) => const InvestmentsHubView()),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF141418),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF818CF8).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.pie_chart_outline_rounded, size: 16, color: Color(0xFF818CF8)),
                ),
                const Text(
                  'EUR',
                  style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '€ ${value.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPortfolioCard(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (ctx) => const InvestmentsHubView()),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: Color(0xFF818CF8), size: 24),
            SizedBox(height: 6),
            Text(
              'Nuovo Portafoglio',
              style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPortfolios(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (ctx) => const InvestmentsHubView()),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF141418),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          child: const Row(
            children: [
              Icon(Icons.trending_up_rounded, color: Color(0xFF818CF8), size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nessun asset di investimento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    SizedBox(height: 2),
                    Text('Inizia a monitorare azioni, ETF, crypto e beni', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}
