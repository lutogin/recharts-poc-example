import React from 'react';
import { ScatterChart, Scatter, XAxis, YAxis, CartesianGrid, ResponsiveContainer, Tooltip, usePlotArea, useXAxisDomain, useYAxisDomain } from 'recharts';
import { mockListings, type ListingStatus } from './mocked-listings';

const RADIUS = 10;
const RADIUS_LEGEND = 14;

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
  Background: '#fafafa',
  /** Grid lines */
  Grid: '#e5e7eb',
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

// Empty circle (original price) — stroke color based on listing status. Transparent fill so the whole circle is hoverable for tooltip.
const OriginalPriceShape = (props) => {
  const { cx, cy, payload } = props;
  if (cx == null || cy == null) return null;
  const color = payload?.listingStatus ? getColorByStatus(payload.listingStatus) : Colors.Neutral;
  const r = RADIUS - 1;
  return (
    <g>
      <circle cx={cx} cy={cy} r={r} fill="transparent" />
      <circle cx={cx} cy={cy} r={r} fill="none" stroke={color} strokeWidth={2} />
    </g>
  );
};

// Filled circle (current price) — fill color based on listing status
const CurrentPriceShape = (props) => {
  const { cx, cy, payload } = props;
  if (cx == null || cy == null) return null;
  const color = payload?.listingStatus ? getColorByStatus(payload.listingStatus) : Colors.Neutral;
  return <circle cx={cx} cy={cy} r={RADIUS} fill={color} />;
};

// Connecting lines component — draws vertical lines between original and current price in chart coordinates
const ConnectingLines = ({ data }: { data: Array<{ days: number; originalPrice: number; currentPrice: number; listingStatus: ListingStatus }> }) => {
  const plotArea = usePlotArea();
  const xDomain = useXAxisDomain() as [number, number] | undefined;
  const yDomain = useYAxisDomain() as [number, number] | undefined;
  if (!plotArea || !xDomain || !yDomain) return null;
  const [xMin, xMax] = xDomain;
  const [yMin, yMax] = yDomain;
  const xRange = xMax - xMin;
  const yRange = yMax - yMin;
  const toX = (days: number) => plotArea.x + ((days - xMin) / xRange) * plotArea.width;
  const toY = (price: number) => plotArea.y + plotArea.height - ((price - yMin) / yRange) * plotArea.height;
  return (
    <g>
      {data.map((item, index) => {
        const x = toX(item.days);
        const y1Center = toY(item.originalPrice);
        const y2 = toY(item.currentPrice);
        const color = getColorByStatus(item.listingStatus);
        // Start line from the contour of the empty circle (towards the second point)
        const dir = Math.sign(y2 - y1Center);
        const y1FromContour = y1Center + dir * RADIUS;
        return (
          <line
            key={`line-${index}`}
            x1={x}
            y1={y1FromContour}
            x2={x}
            y2={y2}
            stroke={color}
            strokeWidth={2}
          />
        );
      })}
    </g>
  );
};

const PriceChangeChart = () => {
  const data = mockListings;

  // Create dataset for original prices (empty circles)
  const originalPricesData = data.map(item => ({
    days: item.days,
    price: item.originalPrice,
    type: 'original' as const,
    originalPrice: item.originalPrice,
    currentPrice: item.currentPrice,
    listingStatus: item.listingStatus,
  }));

  // Create dataset for current prices (filled circles)
  const currentPricesData = data.map(item => ({
    days: item.days,
    price: item.currentPrice,
    type: 'current' as const,
    originalPrice: item.originalPrice,
    currentPrice: item.currentPrice,
    listingStatus: item.listingStatus,
  }));

  // Format price for Y axis
  const formatPrice = (value: number) => {
    if (value >= 1000000) {
      return `$${(value / 1000000).toFixed(2)}M`;
    }
    return `$${(value / 1000).toFixed(0)}K`;
  };

  // Custom tooltip
  const CustomTooltip = ({ active, payload }: any) => {
    if (!active || !payload || !payload.length) return null;
    const point = payload[0].payload;
    const statusColor = point.listingStatus ? getColorByStatus(point.listingStatus) : Colors.Neutral;
    const statusLabel = point.listingStatus
      ? point.listingStatus.charAt(0).toUpperCase() + point.listingStatus.slice(1)
      : 'Unknown';
    const priceChange = point.currentPrice - point.originalPrice;
    const priceChangePercent = ((priceChange / point.originalPrice) * 100).toFixed(1);

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
          {statusLabel} Listing
        </div>
        <div><strong>Days on market:</strong> {point.days}</div>
        <div><strong>Original price:</strong> {formatPrice(point.originalPrice)}</div>
        <div><strong>Current price:</strong> {formatPrice(point.currentPrice)}</div>
        {priceChange !== 0 && (
          <div style={{ marginTop: 8, color: Colors.Neutral }}>
            Price change: {priceChange > 0 ? '+' : ''}{formatPrice(priceChange)} ({priceChange > 0 ? '+' : ''}{priceChangePercent}%)
          </div>
        )}
      </div>
    );
  };

  return (
    <div style={{ width: '100%', maxWidth: 900, padding: 24, background: Colors.Background, fontFamily: 'system-ui, sans-serif' }}>
      <ResponsiveContainer width="100%" height={480}>
        <ScatterChart margin={{ top: 20, right: 60, bottom: 40, left: 40 }}>
          <CartesianGrid strokeDasharray="0" stroke={Colors.Grid} vertical={false} />
          <XAxis
            type="number"
            dataKey="days"
            name="Days on market"
            domain={[0, 240]}
            ticks={[1, 72, 144, 215]}
            tick={{ fontSize: 14, fill: Colors.Neutral }}
            label={{ value: 'Days on market', position: 'insideBottom', offset: -10, style: { fill: Colors.Neutral, fontSize: 14 } }}
            axisLine={false}
            tickLine={false}
          />
          <YAxis
            type="number"
            dataKey="price"
            name="Price"
            orientation="right"
            domain={[760000, 1250000]}
            ticks={[760000, 923000, 1090000, 1250000]}
            tickFormatter={formatPrice}
            tick={{ fontSize: 14, fill: Colors.Neutral }}
            axisLine={false}
            tickLine={false}
            width={70}
          />

          {/* Tooltip on hover */}
          <Tooltip content={<CustomTooltip />} cursor={{ strokeDasharray: '3 3' }} isAnimationActive={false} />

          {/* Connecting lines between original and current price */}
          <ConnectingLines data={data} />

          {/* Scatter for original prices (empty circles) */}
          <Scatter data={originalPricesData} shape={OriginalPriceShape} />

          {/* Scatter for current prices (filled circles) */}
          <Scatter data={currentPricesData} shape={CurrentPriceShape} />
        </ScatterChart>
      </ResponsiveContainer>

      {/* Legend — vertical, left-aligned */}
      <div style={{ marginTop: 24, display: 'flex', flexDirection: 'column', gap: 12, paddingLeft: 8 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{
            width: RADIUS_LEGEND - 2, // - 2px from border
            height: RADIUS_LEGEND - 2, // - 2px from border
            borderRadius: '50%',
            border: `2px solid ${Colors.Neutral}`,
            background: 'none'
          }} />
          <span style={{ color: Colors.Neutral, fontSize: 14 }}>Original list price</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{
            width: RADIUS_LEGEND,
            height: RADIUS_LEGEND,
            borderRadius: '50%',
            background: Colors.Neutral
          }} />
          <span style={{ color: Colors.Neutral, fontSize: 14 }}>Most recent price or sold price</span>
        </div>
      </div>
    </div>
  );
};

export default PriceChangeChart;