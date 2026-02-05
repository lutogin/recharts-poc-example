import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'mocked_listings.dart';

/// Colors for chart elements
class LandChartColors {
  static const Color sold = Color(0xFFC45850); // Muted brownish-red
  static const Color active = Color(0xFF4ABA70); // Muted green
  static const Color pending = Color(0xFF5BC4BE); // Muted turquoise
  static const Color neutral = Color(0xFF6B7280);
  static const Color background = Color(0xFFFFFFFF);
  static const Color grid = Color(0xFFE5E7EB);
  static const Color title = Color(0xFF1E3A8A);
  static const Color text = Color(0xFF4B5563);
  static const Color subjectBorder = Color(0xFF2563EB);
  static const Color confidenceBand = Color(
    0x59_93C5FD,
  ); // rgba(147, 197, 253, 0.35)
  static const Color trendline = Color(0xFFD1D5DB);
}

Color getColorByStatus(ListingStatus status) {
  switch (status) {
    case ListingStatus.sold:
      return LandChartColors.sold;
    case ListingStatus.active:
      return LandChartColors.active;
    case ListingStatus.pending:
      return LandChartColors.pending;
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

/// Linear regression result
class LinearRegressionResult {
  final double a; // intercept
  final double b; // slope

  LinearRegressionResult(this.a, this.b);

  double predict(double x) => a + b * x;
}

LinearRegressionResult linearRegression(List<({double x, double y})> points) {
  final n = points.length;
  double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
  for (final p in points) {
    sumX += p.x;
    sumY += p.y;
    sumXY += p.x * p.y;
    sumX2 += p.x * p.x;
  }
  final b = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
  final a = (sumY - b * sumX) / n;
  return LinearRegressionResult(a, b);
}

class LandPriceChart extends StatefulWidget {
  const LandPriceChart({super.key});

  @override
  State<LandPriceChart> createState() => _LandPriceChartState();
}

class _LandPriceChartState extends State<LandPriceChart> {
  bool showSubjectProperty = true;
  bool showTrendline = true;
  MockListing? _hoveredListing;
  bool _hoveredIsSubject = false;
  Offset? _mousePosition;

  static const double minX = 0.02;
  static const double maxX = 0.06;
  static const int averagePrice = 29569003; // need to be set dynamically

  late final MockListing? subjectListing;
  late final List<MockListing> comparableListings;
  late final LinearRegressionResult? regression;
  
  late final double minY;
  late final double maxY;
  /// Y scale: 4 levels — min, two evenly spaced, max
  late final List<double> yLevels;

  @override
  void initState() {
    super.initState();
    subjectListing = mockListings.where((l) => l.isSubject).firstOrNull;
    comparableListings = mockListings.where((l) => !l.isSubject).toList();

    double minP = double.infinity;
    double maxP = double.negativeInfinity;
    for (final listing in mockListings) {
      if (listing.price < minP) minP = listing.price;
      if (listing.price > maxP) maxP = listing.price;
    }
    minY = minP;
    maxY = maxP;
    final step = (maxY - minY) / 3;
    yLevels = [minY, minY + step, minY + step * 2, maxY];

    // Calculate regression from comparable listings
    if (comparableListings.length >= 2) {
      final points =
          comparableListings.map((l) => (x: l.acres, y: l.price)).toList();
      regression = linearRegression(points);
    } else {
      regression = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: LandChartColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          SizedBox(
            height: 520,
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
                      _hoveredIsSubject = false;
                    });
                  },
                  child: Stack(
                    children: [
                      _buildChart(constraints),
                      _buildRightAxisLabels(constraints.maxWidth, constraints.maxHeight),
                      if (showSubjectProperty && subjectListing != null)
                        _buildSubjectPropertyOverlay(constraints.maxWidth, constraints.maxHeight),
                      if (_hoveredListing != null && _mousePosition != null)
                        _buildTooltip(constraints),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '\$${_formatNumber(averagePrice)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                      color: LandChartColors.title,
                    ),
                  ),
                  TextSpan(
                    text: ' / Acre',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: LandChartColors.text,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: LandChartColors.text),
                children: [
                  const TextSpan(
                    text: 'Comparable land sold for an average of ',
                  ),
                  TextSpan(
                    text: '\$${_formatNumber(averagePrice)}',
                    style: TextStyle(
                      color: LandChartColors.title,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const TextSpan(text: ' / acre.'),
                ],
              ),
            ),
          ],
        ),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: LandChartColors.grid,
          ),
          child: Center(
            child: Text(
              'i',
              style: TextStyle(
                color: LandChartColors.neutral,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
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
                top: (chartH * (1 - i / 3.0) - 6).clamp(0.0, chartH - 12),
                child: Text(
                  formatPrice(yLevels[i]),
                  style: const TextStyle(
                    color: LandChartColors.text,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Subject property: vertical dashed line + house icon (drawn together)
  Widget _buildSubjectPropertyOverlay(double width, double height) {
    final chartW = width - _rightAxisReserved;
    final chartH = height - _bottomMargin;
    // X position from acres
    final fractionX = (subjectListing!.acres - minX) / (maxX - minX);
    final x = fractionX * chartW;
    // Y position from price
    final fractionY = (subjectListing!.price - minY) / (maxY - minY);
    final y = chartH * (1 - fractionY);
    
    const iconRadius = 12.0;
    
    return Positioned.fill(
      bottom: _bottomMargin,
      right: _rightAxisReserved,
      child: IgnorePointer(
        child: CustomPaint(
          painter: _SubjectPropertyOverlayPainter(
            x: x,
            y: y,
            chartHeight: chartH,
            iconRadius: iconRadius,
            lineColor: LandChartColors.neutral,
            iconBorderColor: LandChartColors.subjectBorder,
            iconFillColor: LandChartColors.background,
          ),
        ),
      ),
    );
  }

  Widget _buildChart(BoxConstraints constraints) {
    return CustomPaint(
      painter: _TrendlinePainter(
        regression: showTrendline ? regression : null,
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
      ),
      child: ScatterChart(
        ScatterChartData(
          minX: minX,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          clipData: const FlClipData.none(), // Don't clip points at edges
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            drawHorizontalLine: false, // Disabled - using custom painter
            verticalInterval: (maxX - minX) / 4,
            getDrawingVerticalLine:
                (value) => FlLine(
                  color: LandChartColors.grid,
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false, // drawn by _buildRightAxisLabels
                reservedSize: 70, // must match painter's rightMargin
              ),
            ),
            bottomTitles: AxisTitles(
              axisNameSize: 30,
              axisNameWidget: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Acres',
                  style: TextStyle(color: LandChartColors.text, fontSize: 12),
                ),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval:
                    0.005, // Check at fine intervals to catch 0.025, 0.035, etc.
                getTitlesWidget: (value, meta) {
                  // Show labels at specific X values
                  final validValues = [0.025, 0.035, 0.045, 0.055];
                  for (final v in validValues) {
                    if ((value - v).abs() < 0.001) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          v.toStringAsFixed(3),
                          style: TextStyle(
                            color: LandChartColors.text,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }
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
                  if (spotIndex < comparableListings.length) {
                    setState(() {
                      _hoveredListing = comparableListings[spotIndex];
                      _hoveredIsSubject = false;
                    });
                  } else if (showSubjectProperty && subjectListing != null) {
                    setState(() {
                      _hoveredListing = subjectListing;
                      _hoveredIsSubject = true;
                    });
                  }
                } else {
                  setState(() {
                    _hoveredListing = null;
                    _hoveredIsSubject = false;
                  });
                }
              } else if (event is FlPointerExitEvent) {
                setState(() {
                  _hoveredListing = null;
                  _hoveredIsSubject = false;
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
    const double radius = 6;

    // Comparable listings
    for (final listing in comparableListings) {
      spots.add(
        ScatterSpot(
          listing.acres,
          listing.price,
          dotPainter: FlDotCirclePainter(
            color: getColorByStatus(listing.listingStatus),
            radius: radius,
          ),
        ),
      );
    }

    // Subject property is drawn separately via _buildSubjectPropertyOverlay

    return spots;
  }

  Widget _buildTooltip(BoxConstraints constraints) {
    if (_hoveredListing == null || _mousePosition == null)
      return const SizedBox.shrink();

    final listing = _hoveredListing!;
    final pricePerAcre = listing.price / listing.acres;
    final statusColor =
        _hoveredIsSubject
            ? LandChartColors.subjectBorder
            : getColorByStatus(listing.listingStatus);
    final statusLabel =
        _hoveredIsSubject
            ? 'Subject Property'
            : '${getStatusLabel(listing.listingStatus)} Listing';

    // Position tooltip near cursor, with offset
    const tooltipWidth = 200.0;
    const tooltipHeight = 100.0;
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
          border: Border.all(color: LandChartColors.grid),
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
              statusLabel,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: statusColor,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Acres: ${listing.acres.toStringAsFixed(3)}',
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              'Price: ${formatPrice(listing.price)}',
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              'Price per acre: \$${_formatNumber(pricePerAcre.round())}',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 24,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: showSubjectProperty,
                onChanged:
                    (value) =>
                        setState(() => showSubjectProperty = value ?? true),
                activeColor: LandChartColors.subjectBorder,
              ),
            ),
            const SizedBox(width: 8),
            _buildHouseIcon(),
            const SizedBox(width: 8),
            Text(
              'Subject Property',
              style: TextStyle(color: LandChartColors.text, fontSize: 14),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: showTrendline,
                onChanged:
                    (value) => setState(() => showTrendline = value ?? true),
                activeColor: LandChartColors.subjectBorder,
              ),
            ),
            const SizedBox(width: 8),
            Container(width: 20, height: 2, color: LandChartColors.trendline),
            const SizedBox(width: 8),
            Text(
              'Trendline represents average price per acre of SOLD listings.',
              style: TextStyle(color: LandChartColors.text, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHouseIcon() {
    return CustomPaint(
      size: const Size(16, 16),
      painter: _HouseIconPainter(color: LandChartColors.title),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

/// Draws a vertical dashed line
class _VerticalDashedLinePainter extends CustomPainter {
  final Color color;

  _VerticalDashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashHeight = 4.0;
    const dashSpace = 4.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(0, y),
        Offset(0, math.min(y + dashHeight, size.height)),
        paint,
      );
      y += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalDashedLinePainter old) => color != old.color;
}

/// Draws subject property: vertical dashed line + house icon at exact position
class _SubjectPropertyOverlayPainter extends CustomPainter {
  final double x;
  final double y;
  final double chartHeight;
  final double iconRadius;
  final Color lineColor;
  final Color iconBorderColor;
  final Color iconFillColor;

  _SubjectPropertyOverlayPainter({
    required this.x,
    required this.y,
    required this.chartHeight,
    required this.iconRadius,
    required this.lineColor,
    required this.iconBorderColor,
    required this.iconFillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw vertical dashed line from top to bottom of chart
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashHeight = 4.0;
    const dashSpace = 4.0;
    double currentY = 0;
    while (currentY < chartHeight) {
      canvas.drawLine(
        Offset(x, currentY),
        Offset(x, math.min(currentY + dashHeight, chartHeight)),
        linePaint,
      );
      currentY += dashHeight + dashSpace;
    }

    // Draw house icon at (x, y)
    // White fill circle
    final fillPaint = Paint()
      ..color = iconFillColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), iconRadius, fillPaint);

    // Blue border
    final borderPaint = Paint()
      ..color = iconBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(x, y), iconRadius, borderPaint);

    // House icon inside
    final housePaint = Paint()
      ..color = iconBorderColor
      ..style = PaintingStyle.fill;

    final houseSize = iconRadius * 0.8;
    final houseX = x;
    final houseY = y;

    // Draw simple house shape (pentagon)
    final housePath = Path();
    // Roof peak
    housePath.moveTo(houseX, houseY - houseSize * 0.6);
    // Right roof
    housePath.lineTo(houseX + houseSize * 0.5, houseY - houseSize * 0.1);
    // Right wall
    housePath.lineTo(houseX + houseSize * 0.5, houseY + houseSize * 0.5);
    // Left wall
    housePath.lineTo(houseX - houseSize * 0.5, houseY + houseSize * 0.5);
    // Left roof
    housePath.lineTo(houseX - houseSize * 0.5, houseY - houseSize * 0.1);
    housePath.close();
    canvas.drawPath(housePath, housePaint);
  }

  @override
  bool shouldRepaint(covariant _SubjectPropertyOverlayPainter old) =>
      x != old.x || y != old.y || chartHeight != old.chartHeight;
}

/// Custom painter for trendline and confidence band
class _TrendlinePainter extends CustomPainter {
  final LinearRegressionResult? regression;
  final double minX, maxX, minY, maxY;

  _TrendlinePainter({
    required this.regression,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Chart margins (match fl_chart's layout based on titlesData reservedSizes)
    const double leftMargin = 0; // no left titles
    const double rightMargin = 70; // rightTitles.reservedSize
    const double topMargin = 0; // no top titles
    const double bottomMargin =
        60; // bottomTitles.reservedSize (30) + axisNameSize (30)

    final chartWidth = size.width - leftMargin - rightMargin;
    final chartHeight = size.height - topMargin - bottomMargin;

    double toX(double value) =>
        leftMargin + ((value - minX) / (maxX - minX)) * chartWidth;
    double toY(double value) =>
        topMargin +
        chartHeight -
        ((value - minY) / (maxY - minY)) * chartHeight;

    // Y scale: 4 levels — 4 horizontal grid lines
    final gridPaint = Paint()
      ..color = LandChartColors.grid
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i <= 3; i++) {
      final fraction = i / 3.0;
      final y = topMargin + chartHeight * (1 - fraction);
      
      // Draw dashed line
      const dashWidth = 4.0;
      const dashSpace = 4.0;
      double startX = leftMargin;
      
      while (startX < leftMargin + chartWidth) {
        canvas.drawLine(
          Offset(startX, y),
          Offset(math.min(startX + dashWidth, leftMargin + chartWidth), y),
          gridPaint,
        );
        startX += dashWidth + dashSpace;
      }
    }

    if (regression == null) return;

    final chartRect = Rect.fromLTWH(
      leftMargin,
      topMargin,
      chartWidth,
      chartHeight,
    );

    canvas.save();
    canvas.clipRect(chartRect);

    final yRange = maxY - minY;
    final bandMargin = 0.30 * yRange;

    // Confidence band (drawn inside chart bounds)
    final bandPath = Path();
    final upperLeft = Offset(
      toX(minX),
      toY(regression!.predict(minX) + bandMargin),
    );
    final upperRight = Offset(
      toX(maxX),
      toY(regression!.predict(maxX) + bandMargin),
    );
    final lowerRight = Offset(
      toX(maxX),
      toY(regression!.predict(maxX) - bandMargin),
    );
    final lowerLeft = Offset(
      toX(minX),
      toY(regression!.predict(minX) - bandMargin),
    );

    bandPath.moveTo(upperLeft.dx, upperLeft.dy);
    bandPath.lineTo(upperRight.dx, upperRight.dy);
    bandPath.lineTo(lowerRight.dx, lowerRight.dy);
    bandPath.lineTo(lowerLeft.dx, lowerLeft.dy);
    bandPath.close();

    final bandPaint =
        Paint()
          ..color = LandChartColors.confidenceBand
          ..style = PaintingStyle.fill;
    canvas.drawPath(bandPath, bandPaint);

    // Trendline
    final trendPaint =
        Paint()
          ..color = LandChartColors.trendline
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(toX(minX), toY(regression!.predict(minX))),
      Offset(toX(maxX), toY(regression!.predict(maxX))),
      trendPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TrendlinePainter oldDelegate) {
    return regression != oldDelegate.regression;
  }
}

/// Custom painter for subject property marker (circle with house icon)
class _SubjectPropertyPainter extends FlDotPainter {
  final double radius;

  _SubjectPropertyPainter({required this.radius});

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    // White fill
    final fillPaint =
        Paint()
          ..color = LandChartColors.background
          ..style = PaintingStyle.fill;
    canvas.drawCircle(offsetInCanvas, radius, fillPaint);

    // Blue border
    final borderPaint =
        Paint()
          ..color = LandChartColors.subjectBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
    canvas.drawCircle(offsetInCanvas, radius, borderPaint);

    // House icon (simple pentagon)
    final iconSize = radius * 1.2;
    final iconPaint =
        Paint()
          ..color = LandChartColors.title
          ..style = PaintingStyle.fill;

    final path = Path();
    final cx = offsetInCanvas.dx;
    final cy = offsetInCanvas.dy;
    // Peak, left roof, left wall, right wall, right roof
    path.moveTo(cx, cy - iconSize / 2); // peak
    path.lineTo(cx - iconSize / 2, cy); // left roof
    path.lineTo(cx - iconSize / 2, cy + iconSize / 2); // left wall bottom
    path.lineTo(cx + iconSize / 2, cy + iconSize / 2); // right wall bottom
    path.lineTo(cx + iconSize / 2, cy); // right roof
    path.close();
    canvas.drawPath(path, iconPaint);
  }

  @override
  Size getSize(FlSpot spot) => Size(radius * 2, radius * 2);

  @override
  Color get mainColor => LandChartColors.subjectBorder;

  @override
  List<Object?> get props => [radius];

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) {
    if (a is _SubjectPropertyPainter && b is _SubjectPropertyPainter) {
      return _SubjectPropertyPainter(
        radius: a.radius + (b.radius - a.radius) * t,
      );
    }
    return b;
  }
}

/// Custom painter for house icon
class _HouseIconPainter extends CustomPainter {
  final Color color;

  _HouseIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final path = Path();
    // Simple house pentagon
    path.moveTo(size.width / 2, 0); // peak
    path.lineTo(0, size.height * 0.5); // left roof
    path.lineTo(0, size.height); // left wall bottom
    path.lineTo(size.width, size.height); // right wall bottom
    path.lineTo(size.width, size.height * 0.5); // right roof
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
