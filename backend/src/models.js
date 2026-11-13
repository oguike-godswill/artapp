const mongoose = require('mongoose');
const { Schema, Types } = mongoose;

const toJSON = {
  virtuals: true,
  versionKey: false,
  transform: (_doc, ret) => {
    ret.id = ret._id?.toString();
    delete ret._id;
    delete ret.passwordHash;
    return ret;
  },
};

const UserSchema = new Schema(
  {
    name: { type: String, required: true, trim: true, maxlength: 80 },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    passwordHash: { type: String, required: true },
    favorites: [{ type: Types.ObjectId, ref: 'Artwork' }],
    role: { type: String, enum: ['user', 'admin'], default: 'user' },
  },
  { timestamps: true, toJSON }
);

const RefreshTokenSchema = new Schema(
  {
    user: { type: Types.ObjectId, ref: 'User', required: true, index: true },
    tokenHash: { type: String, required: true, unique: true },
    family: { type: String, required: true, index: true },
    expiresAt: { type: Date, required: true },
    revokedAt: Date,
    replacedBy: String,
  },
  { timestamps: true }
);
RefreshTokenSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

const ArtworkSchema = new Schema(
  {
    title: { type: String, required: true },
    artist: { type: String, required: true },
    medium: String,
    year: Number,
    dimensions: String,
    image: { type: String, required: true },
    description: String,
    series: String,
    printPrice: Number,
    editionSize: Number,
    saves: { type: Number, default: 0 },
    featured: { type: Boolean, default: false },
  },
  { timestamps: true, toJSON }
);

const AuctionSchema = new Schema(
  {
    artwork: { type: Types.ObjectId, ref: 'Artwork', required: true },
    lotNumber: { type: Number, required: true, unique: true },
    startingBid: { type: Number, required: true },
    currentBid: { type: Number, required: true },
    bidCount: { type: Number, default: 0 },
    highestBidder: { type: Types.ObjectId, ref: 'User' },
    startsAt: { type: Date, default: Date.now },
    endsAt: { type: Date, required: true },
  },
  { timestamps: true, toJSON }
);
AuctionSchema.virtual('status').get(function () {
  const now = new Date();
  if (now < this.startsAt) return 'upcoming';
  if (now >= this.endsAt) return 'ended';
  return 'live';
});

const BidSchema = new Schema(
  {
    auction: { type: Types.ObjectId, ref: 'Auction', required: true, index: true },
    user: { type: Types.ObjectId, ref: 'User', required: true, index: true },
    amount: { type: Number, required: true },
  },
  { timestamps: true, toJSON }
);

const ExhibitionSchema = new Schema(
  {
    title: { type: String, required: true },
    gallery: String,
    workCount: Number,
    startsAt: Date,
    endsAt: Date,
    color: { type: String, default: 'rust' },
  },
  { timestamps: true, toJSON }
);

const EventSchema = new Schema(
  {
    title: { type: String, required: true },
    venue: String,
    durationMin: Number,
    price: { type: Number, default: 0 },
    membersFree: { type: Boolean, default: false },
    startsAt: { type: Date, required: true, index: true },
    image: String,
    description: String,
    capacity: { type: Number, default: 100 },
    booked: { type: Number, default: 0 },
  },
  { timestamps: true, toJSON }
);

const BookingSchema = new Schema(
  {
    event: { type: Types.ObjectId, ref: 'Event', required: true },
    user: { type: Types.ObjectId, ref: 'User', required: true },
  },
  { timestamps: true, toJSON }
);
BookingSchema.index({ event: 1, user: 1 }, { unique: true });

module.exports = {
  User: mongoose.model('User', UserSchema),
  RefreshToken: mongoose.model('RefreshToken', RefreshTokenSchema),
  Artwork: mongoose.model('Artwork', ArtworkSchema),
  Auction: mongoose.model('Auction', AuctionSchema),
  Bid: mongoose.model('Bid', BidSchema),
  Exhibition: mongoose.model('Exhibition', ExhibitionSchema),
  Event: mongoose.model('Event', EventSchema),
  Booking: mongoose.model('Booking', BookingSchema),
};
