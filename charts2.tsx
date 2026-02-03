import React, { useMemo, useState } from 'react';
import {
  ScatterChart,
  Scatter,
  XAxis,
  YAxis,
  CartesianGrid,
  ResponsiveContainer,
  ReferenceLine,
  Tooltip,
  usePlotArea,
  useXAxisDomain,
  useYAxisDomain,
} from 'recharts';
import { mockListings, type ListingStatus } from './mocked-listings';

const RADIUS = 6;

const Colors = {
  /** Sold listing — muted brownish-red */
  Sold: '#c45850',
  /** Active listing — muted green */
  Active: '#4aba70',
  /** Pending listing — muted turquoise */
  Pending: '#5bc4be',
  /** Neutral / legend */
  Neutral: '#6b7280',
  /** Chart background */
  Background: '#ffffff',
  /** Grid lines */
  Grid: '#e5e7eb',
  /** Title */
  Title: '#1e3a8a',
  /** Text */
  Text: '#4b5563',
  /** Subject Property border */
  SubjectBorder: '#2563eb',
  /** Confidence band */
  ConfidenceBand: 'rgba(147, 197, 253, 0.35)',
  /** Trendline */
  Trendline: '#d1d5db',
} as const;

// Get color based on listing status
const getColorByStatus = (status: ListingStatus): string => {
  switch (status) {
    case 'sold': return Colors.Sold;
    case 'active': return Colors.Active;
    case 'pending': return Colors.Pending;
    default: return Colors.Neutral;
  }
};

// Linear regression y = a + b*x
function linearRegression(points: { x: number; y: number }[]) {
  const n = points.length;
  let sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
  for (const p of points) {
    sumX += p.x;
    sumY += p.y;
    sumXY += p.x * p.y;
    sumX2 += p.x * p.x;
  }
  const b = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
  const a = (sumY - b * sumX) / n;
  const xMean = sumX / n;
  return { a, b, xMean };
}

// Trendline and confidence band component
const TrendlineAndBand = ({
  comparableData,
}: {
  comparableData: Array<{ acres: number; price: number }>;
}) => {
  const plotArea = usePlotArea();
  const xDomain = useXAxisDomain() as [number, number] | undefined;
  const yDomain = useYAxisDomain() as [number, number] | undefined;

  const { trendPath, bandPath } = useMemo(() => {
    if (!xDomain || !yDomain || !plotArea) return { trendPath: '', bandPath: '' };
    const points = comparableData.map(d => ({ x: d.acres, y: d.price }));
    if (points.length < 2) return { trendPath: '', bandPath: '' };

    const { a, b, xMean } = linearRegression(points);
    const [xMin, xMax] = xDomain;
    const xRange = xMax - xMin;
    const yRange = yDomain[1] - yDomain[0];
    const toX = (v: number) => plotArea.x + ((v - xMin) / xRange) * plotArea.width;
    const toY = (v: number) => plotArea.y + plotArea.height - ((v - yDomain[0]) / yRange) * plotArea.height;

    const xLeft = xMin;
    const xRight = xMax;
    const yLeft = a + b * xLeft;
    const yRight = a + b * xRight;
    // Constant band width (ConfidenceBand)
    const bandMargin = 0.30 * yRange;
    const upper = (x: number) => a + b * x + bandMargin;
    const lower = (x: number) => a + b * x - bandMargin;

    // Simple rectangle (4 points) — straight band along the trendline
    const bandPath = `
      M ${toX(xLeft)} ${toY(upper(xLeft))}
      L ${toX(xRight)} ${toY(upper(xRight))}
      L ${toX(xRight)} ${toY(lower(xRight))}
      L ${toX(xLeft)} ${toY(lower(xLeft))}
      Z
    `;
    const trendPath = `M ${toX(xLeft)} ${toY(yLeft)} L ${toX(xRight)} ${toY(yRight)}`;
    return { trendPath, bandPath };
  }, [comparableData, plotArea, xDomain, yDomain]);

  if (!plotArea || !trendPath) return null;

  return (
    <g>
      <path d={bandPath} fill={Colors.ConfidenceBand} stroke="none" />
      <path d={trendPath} fill="none" stroke={Colors.Trendline} strokeWidth={1.5} />
    </g>
  );
};

// Comparable point — color based on listing status
const ComparablePointShape = (props) => {
  const { cx, cy, payload } = props;
  if (cx == null || cy == null) return null;
  const color = payload?.listingStatus ? getColorByStatus(payload.listingStatus) : Colors.Neutral;
  return <circle cx={cx} cy={cy} r={RADIUS} fill={color} />;
};

// House icon for Subject Property
// Simple house pentagon: peak, two roof slopes, two walls, flat base
const HouseIconSvg = ({ size = 24, color = Colors.Title }: { size?: number; color?: string }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <path
      d="M12 4 L2 12 L2 20 L22 20 L22 12 Z"
      fill={color}
    />
  </svg>
);

// Subject Property point: blue border, white fill, house icon
const SubjectPropertyShape = (props) => {
  const { cx, cy } = props;
  if (cx == null || cy == null) return null;
  const r = 10;
  return (
    <g>
      <circle cx={cx} cy={cy} r={r} fill={Colors.Background} stroke={Colors.SubjectBorder} strokeWidth={2.5} />
      <g transform={`translate(${cx - 6}, ${cy - 6})`}>
        <HouseIconSvg size={12} />
      </g>
    </g>
  );
};

// Custom tooltip
const CustomTooltip = ({ active, payload }: any) => {
  if (!active || !payload || !payload.length) return null;
  const point = payload[0].payload;
  const isSubject = point.isSubject === true;

  const formatPrice = (value: number) => {
    if (value >= 1000000) {
      return `$${(value / 1000000).toFixed(2)}M`;
    }
    return `$${(value / 1000).toFixed(0)}K`;
  };

  const pricePerAcre = point.price / point.acres;
  const statusColor = isSubject
    ? Colors.SubjectBorder
    : point.listingStatus
      ? getColorByStatus(point.listingStatus)
      : Colors.Neutral;
  const statusLabel = isSubject
    ? 'Subject Property'
    : point.listingStatus
      ? `${point.listingStatus.charAt(0).toUpperCase() + point.listingStatus.slice(1)} Listing`
      : 'Comparable Property';

  return (
    <div style={{
      background: '#fff',
      border: `1px solid ${Colors.Grid}`,
      borderRadius: 8,
      padding: '12px 16px',
      boxShadow: '0 4px 12px rgba(0,0,0,0.1)',
      fontSize: 13,
      lineHeight: 1.5,
    }}>
      <div style={{ fontWeight: 600, marginBottom: 8, color: statusColor }}>
        {statusLabel}
      </div>
      <div><strong>Acres:</strong> {point.acres.toFixed(3)}</div>
      <div><strong>Price:</strong> {formatPrice(point.price)}</div>
      <div><strong>Price per acre:</strong> ${Math.round(pricePerAcre).toLocaleString()}</div>
    </div>
  );
};

const LandPriceChart = () => {
  const subjectListing = mockListings.find((l) => l.isSubject);
  const subjectAcres = subjectListing?.acres ?? 0.038;
  const subjectPrice = subjectListing?.price ?? 1_020_000;
  const averagePrice = 29_569_003;

  // State for showing/hiding elements
  const [showSubjectProperty, setShowSubjectProperty] = useState(true);
  const [showTrendline, setShowTrendline] = useState(true);

  // From mocked-listings: comparables (no subject) and subject for chart2
  const comparableData = useMemo(
    () =>
      mockListings
        .filter((l) => !l.isSubject)
        .map((l) => ({ acres: l.acres, price: l.price, listingStatus: l.listingStatus })),
    []
  );
  const subjectData = useMemo(
    () =>
      subjectListing
        ? [{ acres: subjectListing.acres, price: subjectListing.price, isSubject: true as const, listingStatus: subjectListing.listingStatus }]
        : [],
    [subjectListing]
  );

  return (
    <div style={{ width: '100%', maxWidth: 900, padding: 24, background: Colors.Background, fontFamily: 'system-ui, sans-serif' }}>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 8 }}>
        <div>
          <h2 style={{ margin: 0, fontSize: 28, fontWeight: 400, color: Colors.Title }}>
            <span>${averagePrice.toLocaleString()}</span>
            <span style={{ fontSize: 18, fontWeight: 400, color: Colors.Text }}> / Acre</span>
          </h2>
          <p style={{ margin: '4px 0 0', fontSize: 14, color: Colors.Text }}>
            Comparable land sold for an average of{' '}
            <span style={{ color: Colors.Title, fontWeight: 500 }}>${averagePrice.toLocaleString()}</span> / acre.
          </p>
        </div>
        <div
          style={{
            width: 20,
            height: 20,
            borderRadius: '50%',
            background: Colors.Grid,
            color: Colors.Neutral,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: 12,
            fontWeight: 600,
          }}
        >
          i
        </div>
      </div>

      {/* Chart */}
      <ResponsiveContainer width="100%" height={420}>
        <ScatterChart margin={{ top: 16, right: 56, bottom: 32, left: 16 }}>
          <CartesianGrid
            strokeDasharray="4 4"
            stroke={Colors.Grid}
            vertical={true}
            horizontal={true}
          />
          <XAxis
            type="number"
            dataKey="acres"
            name="Acres"
            domain={[0.02, 0.06]}
            ticks={[0.025, 0.035, 0.045, 0.055]}
            tick={{ fontSize: 12, fill: Colors.Text }}
            label={{ value: 'Acres', position: 'insideBottom', offset: -8, style: { fill: Colors.Text } }}
            axisLine={false}
            tickLine={false}
          />
          <YAxis
            type="number"
            dataKey="price"
            domain={[720000, 1200000]}
            ticks={[760000, 898000, 1040000, 1180000]}
            tickFormatter={(v) => `$${v >= 1e6 ? (v / 1e6).toFixed(2) + 'M' : (v / 1e3).toFixed(0) + 'K'}`}
            tick={{ fontSize: 12, fill: Colors.Text }}
            axisLine={false}
            tickLine={false}
            width={52}
            orientation="right"
          />

          {/* Tooltip on hover */}
          <Tooltip content={<CustomTooltip />} cursor={{ strokeDasharray: '3 3' }} isAnimationActive={false} />

          {/* Vertical dashed line at Subject Property */}
          {showSubjectProperty && (
            <ReferenceLine
              x={subjectAcres}
              stroke={Colors.Neutral}
              strokeDasharray="4 4"
              strokeWidth={1}
            />
          )}

          {/* Confidence band and trendline */}
          {showTrendline && <TrendlineAndBand comparableData={comparableData} />}

          {/* Scatter: comparable properties */}
          <Scatter data={comparableData} shape={ComparablePointShape} />

          {/* Scatter: Subject Property */}
          {showSubjectProperty && <Scatter data={subjectData} shape={SubjectPropertyShape} />}
        </ScatterChart>
      </ResponsiveContainer>

      {/* Legend */}
      <div style={{ display: 'flex', gap: 24, alignItems: 'center', marginTop: 16, flexWrap: 'wrap' }}>
        <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer' }}>
          <input
            type="checkbox"
            checked={showSubjectProperty}
            onChange={(e) => setShowSubjectProperty(e.target.checked)}
            style={{ accentColor: Colors.SubjectBorder, cursor: 'pointer' }}
          />
          <HouseIconSvg size={16} />
          <span style={{ color: Colors.Text, fontSize: 14 }}>Subject Property</span>
        </label>
        <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer' }}>
          <input
            type="checkbox"
            checked={showTrendline}
            onChange={(e) => setShowTrendline(e.target.checked)}
            style={{ accentColor: Colors.SubjectBorder, cursor: 'pointer' }}
          />
          <svg width={20} height={10} style={{ verticalAlign: 'middle' }}>
            <line x1={0} y1={8} x2={20} y2={2} stroke={Colors.Trendline} strokeWidth={1.5} />
          </svg>
          <span style={{ color: Colors.Text, fontSize: 14 }}>
            Trendline represents average price per acre of SOLD listings.
          </span>
        </label>
      </div>
    </div>
  );
};

export default LandPriceChart;
