import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'mocked_listings.dart';

/// Colors for listing statuses
class ChartColors {
  static const Color sold = Color(0xFFC45850); // Muted brownish-red
  static const Color active = Color(0xFF4ABA70); // Muted green
  static const Color pending = Color(0xFF5BC4BE); // Muted turquoise
  static const Color neutral = Color(0xFF6B7280);
  static const Color background = Color(0xFFFAFAFA);
  static const Color grid = Color(0xFFE5E7EB);
}

Color getColorByStatus(ListingStatus status) {
  switch (status) {
    case ListingStatus.sold:
      return ChartColors.sold;
    case ListingStatus.active:
      return ChartColors.active;
    case ListingStatus.pending:
      return ChartColors.pending;
  }
}

String formatPrice(double value) {
  if (value >= 1000000) {
    return '\$${(value / 1000000).toStringAsFixed(2)}M';
  }
  return '\$${(value / 1000).toStringAsFixed(0)}K';
}

String getStatusLabel(ListingStatus status) {
  switch (status) {
    case ListingStatus.sold:
      return 'Sold';
    case ListingStatus.active:
      return 'Active';
    case ListingStatus.pending:
      return 'Pending';
  }
}

class PriceChangeChart extends StatefulWidget {
  const PriceChangeChart({super.key});

  @override
  State<PriceChangeChart> createState() => _PriceChangeChartState();
}

class _PriceChangeChartState extends State<PriceChangeChart> {
  MockListing? _hoveredListing;
  Offset? _mousePosition;

  // Chart bounds
  static const double minX = 0;
  static const double maxX = 240;
  static const double radius = 10;

  late final double minY;
  late final double maxY;
  /// Y scale: 4 levels — min, two evenly spaced, max
  late final List<double> yLevels;

  @override
  void initState() {
    super.initState();
    double minP = double.infinity;
    double maxP = double.negativeInfinity;
    for (final listing in mockListings) {
      for (final p in [listing.originalPrice, listing.currentPrice]) {
        if (p < minP) minP = p;
        if (p > maxP) maxP = p;
      }
    }
    minY = minP;
    maxY = maxP;
    final step = (maxY - minY) / 3;
    yLevels = [minY, minY + step, minY + step * 2, maxY];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: ChartColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 560,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return MouseRegion(
                  onHover: (event) {
                    setState(() {
                      _mousePosition = event.localPosition;
                    });
                  },
                  onExit: (_) {
                    setState(() {
                      _mousePosition = null;
                      _hoveredListing = null;
                    });
                  },
                  child: Stack(
                    children: [
                      _buildChart(),
                      _buildRightAxisLabels(constraints.maxWidth, constraints.maxHeight),
                      if (_hoveredListing != null && _mousePosition != null)
                        _buildTooltip(constraints),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildLegend(),
        ],
      ),
    );
  }

  static const double _rightAxisReserved = 70;
  static const double _bottomMargin = 60;

  Widget _buildRightAxisLabels(double width, double height) {
    final chartH = height - _bottomMargin;
    return Positioned(
      right: 0,
      top: 0,
      bottom: _bottomMargin,
      left: width - _rightAxisReserved,
      child: IgnorePointer(
        child: Stack(
          children: [
            for (int i = 0; i < 4; i++)
              Positioned(
                left: 0,
                right: 0,
                top: (chartH * (1 - i / 3.0) - 7).clamp(0.0, chartH - 14),
                child: Text(
                  formatPrice(yLevels[i]),
                  style: const TextStyle(
                    color: ChartColors.neutral,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    return CustomPaint(
      painter: _YGridPainter(gridColor: ChartColors.grid),
      child: ScatterChart(
      ScatterChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.none(), // Don't clip points at edges
        gridData: FlGridData(
          show: false, // Disabled - using custom grid painter
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false), // drawn by _buildRightAxisLabels
          ),
          bottomTitles: AxisTitles(
            axisNameSize: 30,
            axisNameWidget: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Days on market',
                style: TextStyle(color: ChartColors.neutral, fontSize: 14),
              ),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1, // Check every value
              getTitlesWidget: (value, meta) {
                final validValues = [1, 72, 144, 215];
                final intValue = value.round();
                if (validValues.contains(intValue) && (value - intValue).abs() < 0.5) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      intValue.toString(),
                      style: TextStyle(color: ChartColors.neutral, fontSize: 14),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        scatterSpots: _buildScatterSpots(),
        scatterTouchData: ScatterTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          touchCallback: (event, response) {
            if (event is FlPointerHoverEvent || event is FlTapDownEvent) {
              if (response?.touchedSpot != null) {
                final spotIndex = response!.touchedSpot!.spotIndex;
                final totalSpots = mockListings.length;
                if (spotIndex < totalSpots) {
                  // Original price spot
                  setState(() {
                    _hoveredListing = mockListings[spotIndex];
                  });
                } else {
                  // Current price spot
                  setState(() {
                    _hoveredListing = mockListings[spotIndex - totalSpots];
                  });
                }
              } else {
                setState(() {
                  _hoveredListing = null;
                });
              }
            } else if (event is FlPointerExitEvent) {
              setState(() {
                _hoveredListing = null;
              });
            }
          },
        ),
        scatterLabelSettings: ScatterLabelSettings(showLabel: false),
      ),
      ),
    );
  }

  List<ScatterSpot> _buildScatterSpots() {
    final List<ScatterSpot> spots = [];
    
    // Calculate pixel per price unit (approximate chart height is 520 - 60 bottom margin = 460)
    const double chartHeightApprox = 460;
    final double priceRange = maxY - minY;
    final double pixelsPerPriceUnit = chartHeightApprox / priceRange;

    // Original prices (empty circles) with connecting lines
    for (final listing in mockListings) {
      // Calculate pixel offset to current price
      // Positive means current price is below (higher pixel Y)
      final priceOffset = listing.originalPrice - listing.currentPrice;
      final yPixelOffset = priceOffset * pixelsPerPriceUnit;
      
      spots.add(ScatterSpot(
        listing.days.toDouble(),
        listing.originalPrice,
        dotPainter: _OriginalPriceWithLinePainter(
          color: getColorByStatus(listing.listingStatus),
          radius: radius - 1,
          yPixelOffsetToCurrentPrice: yPixelOffset,
        ),
      ));
    }

    // Current prices (filled circles)
    for (final listing in mockListings) {
      spots.add(ScatterSpot(
        listing.days.toDouble(),
        listing.currentPrice,
        dotPainter: FlDotCirclePainter(
          color: getColorByStatus(listing.listingStatus),
          radius: radius,
        ),
      ));
    }

    return spots;
  }

  Widget _buildTooltip(BoxConstraints constraints) {
    if (_hoveredListing == null || _mousePosition == null) return const SizedBox.shrink();

    final listing = _hoveredListing!;
    final statusColor = getColorByStatus(listing.listingStatus);
    final priceChange = listing.currentPrice - listing.originalPrice;
    final priceChangePercent = (priceChange / listing.originalPrice * 100).toStringAsFixed(1);

    // Position tooltip near cursor, with offset
    const tooltipWidth = 200.0;
    const tooltipHeight = 120.0;
    double left = _mousePosition!.dx + 16;
    double top = _mousePosition!.dy + 16;

    // Prevent tooltip from going outside bounds
    if (left + tooltipWidth > constraints.maxWidth) {
      left = _mousePosition!.dx - tooltipWidth - 16;
    }
    if (top + tooltipHeight > constraints.maxHeight) {
      top = _mousePosition!.dy - tooltipHeight - 16;
    }

    return Positioned(
      left: left,
      top: top,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ChartColors.grid),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${getStatusLabel(listing.listingStatus)} Listing',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: statusColor,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text('Days on market: ${listing.days}', style: const TextStyle(fontSize: 13)),
            Text('Original price: ${formatPrice(listing.originalPrice)}', style: const TextStyle(fontSize: 13)),
            Text('Current price: ${formatPrice(listing.currentPrice)}', style: const TextStyle(fontSize: 13)),
            if (priceChange != 0) ...[
              const SizedBox(height: 8),
              Text(
                'Price change: ${priceChange > 0 ? '+' : ''}${formatPrice(priceChange)} (${priceChange > 0 ? '+' : ''}$priceChangePercent%)',
                style: TextStyle(fontSize: 13, color: ChartColors.neutral),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ChartColors.neutral, width: 2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Original list price',
              style: TextStyle(color: ChartColors.neutral, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ChartColors.neutral,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Most recent price or sold price',
              style: TextStyle(color: ChartColors.neutral, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }
}

/// Custom painter for original price: empty circle + connecting line to current price
class _OriginalPriceWithLinePainter extends FlDotPainter {
  final Color color;
  final double radius;
  final double yPixelOffsetToCurrentPrice;

  _OriginalPriceWithLinePainter({
    required this.color,
    required this.radius,
    required this.yPixelOffsetToCurrentPrice,
  });

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    // Draw connecting line first (so it's behind the circle)
    if (yPixelOffsetToCurrentPrice.abs() > radius * 2) {
      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      
      // Line starts from circle contour, not center
      final dir = yPixelOffsetToCurrentPrice.sign;
      final lineStartY = offsetInCanvas.dy + dir * radius;
      final lineEndY = offsetInCanvas.dy + yPixelOffsetToCurrentPrice;
      
      canvas.drawLine(
        Offset(offsetInCanvas.dx, lineStartY),
        Offset(offsetInCanvas.dx, lineEndY),
        linePaint,
      );
    }
    
    // Draw empty circle (stroke only)
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(offsetInCanvas, radius, strokePaint);
    
    // Draw transparent fill for hover detection
    final fillPaint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(offsetInCanvas, radius, fillPaint);
  }

  @override
  Size getSize(FlSpot spot) => Size(radius * 2, radius * 2);

  @override
  Color get mainColor => color;

  @override
  List<Object?> get props => [color, radius, yPixelOffsetToCurrentPrice];

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) {
    if (a is _OriginalPriceWithLinePainter && b is _OriginalPriceWithLinePainter) {
      return _OriginalPriceWithLinePainter(
        color: Color.lerp(a.color, b.color, t) ?? b.color,
        radius: a.radius + (b.radius - a.radius) * t,
        yPixelOffsetToCurrentPrice: a.yPixelOffsetToCurrentPrice + (b.yPixelOffsetToCurrentPrice - a.yPixelOffsetToCurrentPrice) * t,
      );
    }
    return b;
  }
}

/// Draws 4 horizontal grid lines (Y scale: min, two mid levels, max)
class _YGridPainter extends CustomPainter {
  final Color gridColor;

  _YGridPainter({required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    const rightMargin = 70.0;
    const bottomMargin = 60.0;
    final w = size.width - rightMargin;
    final h = size.height - bottomMargin;

    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 3; i++) {
      final y = h * (1 - i / 3.0);
      canvas.drawLine(Offset(0, y), Offset(w, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _YGridPainter old) => gridColor != old.gridColor;
}

