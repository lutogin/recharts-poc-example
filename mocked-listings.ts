/**
 * Mock listings data for Price Change chart (charts.tsx) and Land Price chart (charts2.tsx).
 * Each listing has: id, listingStatus, days/originalPrice/currentPrice (chart1), acres/price (chart2), isSubject (chart2 subject property).
 */

export type ListingStatus = 'sold' | 'active' | 'pending';

export interface MockListing {
  id: number;
  listingStatus: ListingStatus;
  // Price change chart (chart1)
  days: number;
  originalPrice: number;
  currentPrice: number;
  // Land price chart (chart2)
  acres: number;
  price: number;
  /** True for the subject property in chart2 */
  isSubject?: boolean;
}

export const mockListings: MockListing[] = [
  // Left edge (day 1-12) — id 1 is subject property for chart2
  { id: 1, days: 3, originalPrice: 1090000, currentPrice: 1090000, listingStatus: 'pending', acres: 0.038, price: 1_020_000, isSubject: true },
  { id: 2, days: 5, originalPrice: 1020000, currentPrice: 1020000, listingStatus: 'pending', acres: 0.024, price: 850000 },
  { id: 3, days: 18, originalPrice: 1000000, currentPrice: 1030000, listingStatus: 'active', acres: 0.027, price: 920000 },
  { id: 4, days: 6, originalPrice: 970000, currentPrice: 940000, listingStatus: 'sold', acres: 0.025, price: 760000 },
  { id: 5, days: 8, originalPrice: 950000, currentPrice: 920000, listingStatus: 'sold', acres: 0.028, price: 890000 },
  { id: 6, days: 11, originalPrice: 870000, currentPrice: 840000, listingStatus: 'sold', acres: 0.029, price: 930000 },

  // Day ~35
  { id: 7, days: 38, originalPrice: 820000, currentPrice: 790000, listingStatus: 'sold', acres: 0.030, price: 870000 },

  // Area 72-100: cluster
  { id: 8, days: 72, originalPrice: 1150000, currentPrice: 1050000, listingStatus: 'pending', acres: 0.031, price: 910000 },
  { id: 9, days: 78, originalPrice: 1080000, currentPrice: 1080000, listingStatus: 'pending', acres: 0.033, price: 950000 },
  { id: 10, days: 82, originalPrice: 1080000, currentPrice: 980000, listingStatus: 'sold', acres: 0.034, price: 830000 },
  { id: 11, days: 85, originalPrice: 1000000, currentPrice: 960000, listingStatus: 'sold', acres: 0.035, price: 1170000 },
  { id: 12, days: 88, originalPrice: 980000, currentPrice: 1000000, listingStatus: 'active', acres: 0.039, price: 980000 },
  { id: 13, days: 92, originalPrice: 960000, currentPrice: 940000, listingStatus: 'sold', acres: 0.044, price: 1000000 },
  { id: 14, days: 95, originalPrice: 940000, currentPrice: 960000, listingStatus: 'active', acres: 0.045, price: 1100000 },

  // Day ~125
  { id: 15, days: 125, originalPrice: 1010000, currentPrice: 920000, listingStatus: 'sold', acres: 0.046, price: 1040000 },

  // Day ~135-155
  { id: 16, days: 135, originalPrice: 930000, currentPrice: 930000, listingStatus: 'pending', acres: 0.047, price: 1080000 },
  { id: 17, days: 148, originalPrice: 790000, currentPrice: 760000, listingStatus: 'sold', acres: 0.048, price: 1020000 },
  { id: 18, days: 155, originalPrice: 880000, currentPrice: 850000, listingStatus: 'sold', acres: 0.052, price: 810000 },

  // Day ~170
  { id: 19, days: 170, originalPrice: 1000000, currentPrice: 920000, listingStatus: 'sold', acres: 0.057, price: 1180000 },

  // Right edge (215-225)
  { id: 20, days: 215, originalPrice: 990000, currentPrice: 960000, listingStatus: 'sold', acres: 0.024, price: 850000 },
  { id: 21, days: 218, originalPrice: 920000, currentPrice: 960000, listingStatus: 'active', acres: 0.028, price: 890000 },
  { id: 22, days: 220, originalPrice: 1000000, currentPrice: 1000000, listingStatus: 'pending', acres: 0.032, price: 940000 },
  { id: 23, days: 222, originalPrice: 920000, currentPrice: 960000, listingStatus: 'active', acres: 0.036, price: 990000 },
  { id: 24, days: 225, originalPrice: 1250000, currentPrice: 1150000, listingStatus: 'sold', acres: 0.042, price: 1050000 },
];
