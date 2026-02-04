// Mock listings data for Price Change chart and Land Price chart.
// Each listing has: id, listingStatus, days/originalPrice/currentPrice (chart1), acres/price (chart2), isSubject (chart2 subject property).

enum ListingStatus { sold, active, pending }

class MockListing {
  final int id;
  final ListingStatus listingStatus;
  // Price change chart (chart1)
  final int days;
  final double originalPrice;
  final double currentPrice;
  // Land price chart (chart2)
  final double acres;
  final double price;
  /// True for the subject property in chart2
  final bool isSubject;

  const MockListing({
    required this.id,
    required this.listingStatus,
    required this.days,
    required this.originalPrice,
    required this.currentPrice,
    required this.acres,
    required this.price,
    this.isSubject = false,
  });
}

const List<MockListing> mockListings = [
  // Left edge (day 1-12) — id 1 is subject property for chart2
  MockListing(id: 1, days: 3, originalPrice: 1090000, currentPrice: 1090000, listingStatus: ListingStatus.pending, acres: 0.038, price: 1020000, isSubject: true),
  MockListing(id: 2, days: 5, originalPrice: 1020000, currentPrice: 1020000, listingStatus: ListingStatus.pending, acres: 0.024, price: 850000),
  MockListing(id: 3, days: 18, originalPrice: 1000000, currentPrice: 1030000, listingStatus: ListingStatus.active, acres: 0.027, price: 920000),
  MockListing(id: 4, days: 6, originalPrice: 970000, currentPrice: 940000, listingStatus: ListingStatus.sold, acres: 0.025, price: 760000),
  MockListing(id: 5, days: 8, originalPrice: 950000, currentPrice: 920000, listingStatus: ListingStatus.sold, acres: 0.028, price: 890000),
  MockListing(id: 6, days: 11, originalPrice: 870000, currentPrice: 840000, listingStatus: ListingStatus.sold, acres: 0.029, price: 930000),

  // Day ~35
  MockListing(id: 7, days: 38, originalPrice: 820000, currentPrice: 790000, listingStatus: ListingStatus.sold, acres: 0.030, price: 870000),

  // Area 72-100: cluster
  MockListing(id: 8, days: 72, originalPrice: 1150000, currentPrice: 1050000, listingStatus: ListingStatus.pending, acres: 0.031, price: 910000),
  MockListing(id: 9, days: 78, originalPrice: 1080000, currentPrice: 1080000, listingStatus: ListingStatus.pending, acres: 0.033, price: 950000),
  MockListing(id: 10, days: 82, originalPrice: 1080000, currentPrice: 980000, listingStatus: ListingStatus.sold, acres: 0.034, price: 830000),
  MockListing(id: 11, days: 85, originalPrice: 1000000, currentPrice: 960000, listingStatus: ListingStatus.sold, acres: 0.035, price: 1170000),
  MockListing(id: 12, days: 88, originalPrice: 980000, currentPrice: 1000000, listingStatus: ListingStatus.active, acres: 0.039, price: 980000),
  MockListing(id: 13, days: 92, originalPrice: 960000, currentPrice: 940000, listingStatus: ListingStatus.sold, acres: 0.044, price: 1000000),
  MockListing(id: 14, days: 95, originalPrice: 940000, currentPrice: 960000, listingStatus: ListingStatus.active, acres: 0.045, price: 1100000),

  // Day ~125
  MockListing(id: 15, days: 125, originalPrice: 1010000, currentPrice: 920000, listingStatus: ListingStatus.sold, acres: 0.046, price: 1040000),

  // Day ~135-155
  MockListing(id: 16, days: 135, originalPrice: 930000, currentPrice: 930000, listingStatus: ListingStatus.pending, acres: 0.047, price: 1080000),
  MockListing(id: 17, days: 148, originalPrice: 790000, currentPrice: 760000, listingStatus: ListingStatus.sold, acres: 0.048, price: 1020000),
  MockListing(id: 18, days: 155, originalPrice: 880000, currentPrice: 850000, listingStatus: ListingStatus.sold, acres: 0.052, price: 810000),

  // Day ~170
  MockListing(id: 19, days: 170, originalPrice: 1000000, currentPrice: 920000, listingStatus: ListingStatus.sold, acres: 0.057, price: 1180000),

  // Right edge (215-225)
  MockListing(id: 20, days: 215, originalPrice: 990000, currentPrice: 960000, listingStatus: ListingStatus.sold, acres: 0.024, price: 850000),
  MockListing(id: 21, days: 218, originalPrice: 920000, currentPrice: 960000, listingStatus: ListingStatus.active, acres: 0.028, price: 890000),
  MockListing(id: 22, days: 220, originalPrice: 1000000, currentPrice: 1000000, listingStatus: ListingStatus.pending, acres: 0.032, price: 940000),
  MockListing(id: 23, days: 222, originalPrice: 920000, currentPrice: 960000, listingStatus: ListingStatus.active, acres: 0.036, price: 990000),
  MockListing(id: 24, days: 225, originalPrice: 1250000, currentPrice: 1150000, listingStatus: ListingStatus.sold, acres: 0.042, price: 1050000),
];
