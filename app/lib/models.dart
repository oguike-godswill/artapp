class User {
  final String id, name, email;
  User({required this.id, required this.name, required this.email});
  factory User.fromJson(Map<String, dynamic> j) =>
      User(id: j['id'] as String, name: j['name'] as String, email: j['email'] as String);
  String get initials {
    final p = name.trim().split(RegExp(r'\s+'));
    return (p.first[0] + (p.length > 1 ? p.last[0] : '')).toUpperCase();
  }
}

class Artwork {
  final String id, title, artist, image;
  final String? medium, dimensions, description, series;
  final int? year, printPrice, editionSize;
  final int saves;
  bool isFavorite;

  Artwork.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        title = j['title'] as String,
        artist = j['artist'] as String,
        image = j['image'] as String,
        medium = j['medium'] as String?,
        dimensions = j['dimensions'] as String?,
        description = j['description'] as String?,
        series = j['series'] as String?,
        year = (j['year'] as num?)?.toInt(),
        printPrice = (j['printPrice'] as num?)?.toInt(),
        editionSize = (j['editionSize'] as num?)?.toInt(),
        saves = (j['saves'] as num?)?.toInt() ?? 0,
        isFavorite = j['isFavorite'] == true;

  String get byline => [artist, medium, if (year != null) '$year'].whereType<String>().join(' · ');
}

class Auction {
  final String id, status;
  final Artwork artwork;
  final int lotNumber, startingBid, currentBid, bidCount, minNextBid;
  final DateTime startsAt, endsAt;
  final bool isLeading;

  Auction.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        status = j['status'] as String? ?? 'live',
        artwork = Artwork.fromJson(j['artwork'] as Map<String, dynamic>),
        lotNumber = (j['lotNumber'] as num).toInt(),
        startingBid = (j['startingBid'] as num).toInt(),
        currentBid = (j['currentBid'] as num).toInt(),
        bidCount = (j['bidCount'] as num?)?.toInt() ?? 0,
        minNextBid = (j['minNextBid'] as num).toInt(),
        startsAt = DateTime.parse(j['startsAt'] as String).toLocal(),
        endsAt = DateTime.parse(j['endsAt'] as String).toLocal(),
        isLeading = j['isLeading'] == true;

  bool get isLive => status == 'live' && endsAt.isAfter(DateTime.now());
  String get lot => 'LOT ${lotNumber.toString().padLeft(3, '0')}';

  /// fraction of time elapsed (for the progress bar)
  double get progress {
    final total = endsAt.difference(startsAt).inSeconds;
    if (total <= 0) return 1;
    return (DateTime.now().difference(startsAt).inSeconds / total).clamp(0, 1).toDouble();
  }
}

class BidEntry {
  final String id, bidder;
  final int amount;
  final DateTime createdAt;
  final bool isMine;
  BidEntry.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        bidder = j['bidder'] as String,
        amount = (j['amount'] as num).toInt(),
        createdAt = DateTime.parse(j['createdAt'] as String).toLocal(),
        isMine = j['isMine'] == true;
}

class Exhibition {
  final String title;
  final String? gallery;
  final int workCount;
  Exhibition.fromJson(Map<String, dynamic> j)
      : title = j['title'] as String,
        gallery = j['gallery'] as String?,
        workCount = (j['workCount'] as num?)?.toInt() ?? 0;
}

class Series {
  final String name;
  final int count;
  final List<String> images;
  Series.fromJson(Map<String, dynamic> j)
      : name = j['name'] as String,
        count = (j['count'] as num).toInt(),
        images = (j['images'] as List).cast<String>();
}

class SolisEvent {
  final String id, title;
  final String? venue, image, description;
  final int durationMin, price, capacity, booked;
  final bool membersFree;
  final DateTime startsAt;
  bool isBooked;

  SolisEvent.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        title = j['title'] as String,
        venue = j['venue'] as String?,
        image = j['image'] as String?,
        description = j['description'] as String?,
        durationMin = (j['durationMin'] as num?)?.toInt() ?? 60,
        price = (j['price'] as num?)?.toInt() ?? 0,
        capacity = (j['capacity'] as num?)?.toInt() ?? 0,
        booked = (j['booked'] as num?)?.toInt() ?? 0,
        membersFree = j['membersFree'] == true,
        startsAt = DateTime.parse(j['startsAt'] as String).toLocal(),
        isBooked = j['isBooked'] == true;

  String get priceLabel => price == 0 ? 'Free' : '\$$price';
  String get meta => [venue, '$durationMin min', priceLabel, if (membersFree) 'Members free'].whereType<String>().join(' · ');
  int get spotsLeft => (capacity - booked).clamp(0, capacity);
}
