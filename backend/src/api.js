const express = require('express');
const mongoose = require('mongoose');
const { z } = require('zod');
const config = require('./config');
const { Artwork, Auction, Bid, Exhibition, Event, Booking, User } = require('./models');
const { asyncH, HttpError, validate, objectId } = require('./util');
const { requireAuth, optionalAuth } = require('./auth');
const { broadcast } = require('./realtime');
const fallback = require('./fallbackData');

const router = express.Router();

const isDbReady = () => mongoose.connection.readyState === 1;
const auctionPop = { path: 'artwork' };

// In-memory fallback tracking for seamless offline/initial runs
const memFavs = new Map(); // userId -> Set<artId>
const memBookings = new Map(); // userId -> Set<eventId>
const memUserBids = new Map(); // userId -> Map<auctionId, { myMax: number, auction: object }>

function auctionView(a, userId) {
  const j = a.toJSON();
  j.minNextBid = a.currentBid + config.minBidIncrement;
  j.isLeading = !!userId && a.highestBidder?.toString() === userId;
  delete j.highestBidder;
  return j;
}

async function favSet(userId) {
  if (!userId) return new Set();
  const u = await User.findById(userId).select('favorites');
  return new Set((u?.favorites || []).map(String));
}
const artView = (a, favs) => ({ ...a.toJSON(), isFavorite: favs.has(a.id) });

// ---------- Discover ----------
router.get(
  '/discover',
  optionalAuth,
  asyncH(async (req, res) => {
    if (!isDbReady()) {
      return res.json({
        featured: fallback.auctions[0],
        auctions: fallback.auctions.slice(1),
      });
    }
    const now = new Date();
    const live = await Auction.find({ startsAt: { $lte: now }, endsAt: { $gt: now } })
      .sort({ endsAt: 1 })
      .populate(auctionPop);
    const featuredArt = await Artwork.findOne({ featured: true });
    let featured = live.find((a) => featuredArt && a.artwork?.id === featuredArt.id) || live[0] || null;
    res.json({
      featured: featured ? auctionView(featured, req.userId) : null,
      auctions: live.filter((a) => a !== featured).map((a) => auctionView(a, req.userId)),
    });
  })
);

// ---------- Collection ----------
router.get(
  '/collection',
  optionalAuth,
  asyncH(async (req, res) => {
    if (!isDbReady()) {
      const favs = memFavs.get(req.userId) || new Set();
      let list = fallback.artworks.map((a) => ({ ...a, isFavorite: favs.has(a.id) }));
      if (req.query.q) {
        const q = String(req.query.q).toLowerCase();
        list = list.filter((a) => a.title.toLowerCase().includes(q) || a.artist.toLowerCase().includes(q));
      }
      if (req.query.favorites === 'true') {
        list = list.filter((a) => favs.has(a.id));
      }
      return res.json({
        artworks: list,
        exhibition: fallback.exhibition,
        liveAuction: fallback.auctions[0],
        series: { name: 'Water series', count: 3, images: fallback.artworks.slice(0, 3).map((a) => a.image) },
      });
    }
    const favs = await favSet(req.userId);
    const filter = {};
    if (req.query.q) filter.title = { $regex: String(req.query.q).replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), $options: 'i' };
    if (req.query.favorites === 'true') filter._id = { $in: [...favs] };
    const artworks = await Artwork.find(filter).sort({ createdAt: 1 });
    const now = new Date();
    const exhibition = await Exhibition.findOne({ startsAt: { $lte: now }, endsAt: { $gt: now } });
    const liveAuction = await Auction.findOne({ startsAt: { $lte: now }, endsAt: { $gt: now } })
      .sort({ lotNumber: -1 })
      .populate(auctionPop);
    const seriesAgg = await Artwork.aggregate([
      { $match: { series: { $ne: null } } },
      { $group: { _id: '$series', count: { $sum: 1 }, images: { $push: '$image' } } },
      { $sort: { count: -1 } },
      { $limit: 1 },
    ]);
    const s = seriesAgg[0];
    res.json({
      artworks: artworks.map((a) => artView(a, favs)),
      exhibition,
      liveAuction: liveAuction ? auctionView(liveAuction, req.userId) : null,
      series: s ? { name: s._id, count: s.count, images: s.images.slice(0, 3) } : null,
    });
  })
);

router.get(
  '/artworks/:id',
  optionalAuth,
  asyncH(async (req, res) => {
    if (!isDbReady()) {
      const art = fallback.artworks.find((a) => a.id === req.params.id || a._id === req.params.id) || fallback.artworks[0];
      const favs = memFavs.get(req.userId) || new Set();
      const auc = fallback.auctions.find((a) => a.artwork?.id === art.id || a.artwork?._id === art.id);
      return res.json({ artwork: { ...art, isFavorite: favs.has(art.id) }, auction: auc || null });
    }
    const art = await Artwork.findById(objectId(req.params.id));
    if (!art) throw new HttpError(404, 'Artwork not found');
    const favs = await favSet(req.userId);
    const auction = await Auction.findOne({ artwork: art._id, endsAt: { $gt: new Date() } }).populate(auctionPop);
    res.json({ artwork: artView(art, favs), auction: auction ? auctionView(auction, req.userId) : null });
  })
);

router.post(
  '/artworks/:id/favorite',
  requireAuth,
  asyncH(async (req, res) => {
    if (!isDbReady() || req.userId?.startsWith('mem_')) {
      let set = memFavs.get(req.userId);
      if (!set) {
        set = new Set();
        memFavs.set(req.userId, set);
      }
      const has = set.has(req.params.id);
      if (has) set.delete(req.params.id);
      else set.add(req.params.id);
      return res.json({ isFavorite: !has });
    }
    const id = objectId(req.params.id);
    if (!(await Artwork.exists({ _id: id }))) throw new HttpError(404, 'Artwork not found');
    const user = await User.findById(req.userId).select('favorites');
    const has = user.favorites.some((f) => f.toString() === id);
    await User.updateOne({ _id: req.userId }, has ? { $pull: { favorites: id } } : { $addToSet: { favorites: id } });
    await Artwork.updateOne({ _id: id }, { $inc: { saves: has ? -1 : 1 } });
    res.json({ isFavorite: !has });
  })
);

// ---------- Auctions ----------
router.get(
  '/auctions',
  optionalAuth,
  asyncH(async (req, res) => {
    if (!isDbReady()) {
      return res.json({ auctions: fallback.auctions });
    }
    const list = await Auction.find({}).sort({ endsAt: 1 }).populate(auctionPop);
    res.json({ auctions: list.map((a) => auctionView(a, req.userId)) });
  })
);

router.get(
  '/auctions/:id',
  optionalAuth,
  asyncH(async (req, res) => {
    if (!isDbReady()) {
      const a = fallback.auctions.find((x) => x.id === req.params.id || x._id === req.params.id) || fallback.auctions[0];
      return res.json({
        auction: a,
        bids: [
          { id: 'b-1', amount: a.currentBid, bidder: 'VIP Paddle #42', createdAt: new Date().toISOString(), isMine: false },
        ],
      });
    }
    const a = await Auction.findById(objectId(req.params.id)).populate(auctionPop);
    if (!a) throw new HttpError(404, 'Auction not found');
    const bids = await Bid.find({ auction: a._id }).sort({ createdAt: -1 }).limit(10).populate('user', 'name');
    const favs = await favSet(req.userId);
    res.json({
      auction: { ...auctionView(a, req.userId), artwork: artView(a.artwork, favs) },
      bids: bids.map((b) => ({
        id: b.id,
        amount: b.amount,
        createdAt: b.createdAt,
        bidder: b.user?.name ? b.user.name.split(' ')[0] : 'Bidder',
        isMine: b.user?._id?.toString() === req.userId,
      })),
    });
  })
);

router.post(
  '/auctions/:id/bids',
  requireAuth,
  asyncH(async (req, res) => {
    const { amount } = validate(z.object({ amount: z.number().int().positive().max(100_000_000) }), req.body);
    if (!isDbReady() || req.userId?.startsWith('mem_')) {
      const a = fallback.auctions.find((x) => x.id === req.params.id || x._id === req.params.id) || fallback.auctions[0];
      if (amount <= a.currentBid) {
        throw new HttpError(409, `Bid must be at least $${(a.currentBid + config.minBidIncrement).toLocaleString('en-US')}`);
      }
      a.currentBid = amount;
      a.bidCount = (a.bidCount || 0) + 1;
      a.minNextBid = amount + config.minBidIncrement;
      a.highestBidder = req.userId;

      // Track bid under user profile
      let userBids = memUserBids.get(req.userId);
      if (!userBids) {
        userBids = new Map();
        memUserBids.set(req.userId, userBids);
      }
      userBids.set(a.id, {
        myMax: amount,
        auction: { ...a, currentBid: amount, bidCount: a.bidCount, minNextBid: a.minNextBid, isLeading: true },
      });

      broadcast({
        type: 'bid',
        auctionId: a.id,
        currentBid: amount,
        bidCount: a.bidCount,
        highestBidderId: req.userId,
        bidder: 'You',
        minNextBid: a.minNextBid,
        artworkTitle: a.artwork?.title || 'Lot',
        time: new Date().toISOString(),
      });
      return res.status(201).json({ auction: { ...a, isLeading: true } });
    }
    const id = objectId(req.params.id);
    const now = new Date();
    // Atomic compare-and-set: only succeeds if the auction is live and the amount still clears the increment.
    const updated = await Auction.findOneAndUpdate(
      {
        _id: id,
        startsAt: { $lte: now },
        endsAt: { $gt: now },
        currentBid: { $lte: amount - config.minBidIncrement },
      },
      { $set: { currentBid: amount, highestBidder: req.userId }, $inc: { bidCount: 1 } },
      { new: true }
    ).populate(auctionPop);
    if (!updated) {
      const a = await Auction.findById(id);
      if (!a) throw new HttpError(404, 'Auction not found');
      if (a.status !== 'live') throw new HttpError(409, 'This auction is not live');
      throw new HttpError(409, `Bid must be at least $${(a.currentBid + config.minBidIncrement).toLocaleString('en-US')}`);
    }
    await Bid.create({ auction: id, user: req.userId, amount });
    const userDoc = await User.findById(req.userId).select('name');
    const bidderName = userDoc?.name ? userDoc.name.split(' ')[0] : 'Collector';

    broadcast({
      type: 'bid',
      auctionId: id.toString(),
      currentBid: amount,
      bidCount: updated.bidCount,
      highestBidderId: req.userId.toString(),
      bidder: bidderName,
      minNextBid: amount + config.minBidIncrement,
      artworkTitle: updated.artwork?.title || 'Lot',
      time: new Date().toISOString(),
    });

    res.status(201).json({ auction: auctionView(updated, req.userId) });
  })
);

// ---------- Events ----------
router.get(
  '/events',
  optionalAuth,
  asyncH(async (req, res) => {
    if (!isDbReady() || req.userId?.startsWith('mem_')) {
      const booked = memBookings.get(req.userId) || new Set();
      return res.json({ events: fallback.events.map((e) => ({ ...e, isBooked: booked.has(e.id) })) });
    }
    const from = req.query.from ? new Date(String(req.query.from)) : new Date(new Date().setHours(0, 0, 0, 0));
    const to = req.query.to ? new Date(String(req.query.to)) : new Date(from.getTime() + 60 * 864e5);
    if (isNaN(from) || isNaN(to)) throw new HttpError(400, 'Invalid date range');
    const events = await Event.find({ startsAt: { $gte: from, $lt: to } }).sort({ startsAt: 1 });
    let booked = new Set();
    if (req.userId) {
      const bk = await Booking.find({ user: req.userId, event: { $in: events.map((e) => e._id) } });
      booked = new Set(bk.map((b) => b.event.toString()));
    }
    res.json({ events: events.map((e) => ({ ...e.toJSON(), isBooked: booked.has(e.id) })) });
  })
);

router.get(
  '/events/:id',
  optionalAuth,
  asyncH(async (req, res) => {
    if (!isDbReady() || req.userId?.startsWith('mem_')) {
      const e = fallback.events.find((x) => x.id === req.params.id || x._id === req.params.id) || fallback.events[0];
      const booked = (memBookings.get(req.userId) || new Set()).has(e.id);
      return res.json({ event: { ...e, isBooked: booked } });
    }
    const e = await Event.findById(objectId(req.params.id));
    if (!e) throw new HttpError(404, 'Event not found');
    const isBooked = req.userId ? !!(await Booking.exists({ event: e._id, user: req.userId })) : false;
    res.json({ event: { ...e.toJSON(), isBooked } });
  })
);

router.post(
  '/events/:id/book',
  requireAuth,
  asyncH(async (req, res) => {
    if (!isDbReady() || req.userId?.startsWith('mem_')) {
      let set = memBookings.get(req.userId);
      if (!set) {
        set = new Set();
        memBookings.set(req.userId, set);
      }
      set.add(req.params.id);
      const e = fallback.events.find((x) => x.id === req.params.id || x._id === req.params.id) || fallback.events[0];
      return res.status(201).json({ event: { ...e, isBooked: true } });
    }
    const id = objectId(req.params.id);
    if (await Booking.exists({ event: id, user: req.userId })) throw new HttpError(409, 'Already booked');
    const e = await Event.findOneAndUpdate(
      { _id: id, startsAt: { $gt: new Date() }, $expr: { $lt: ['$booked', '$capacity'] } },
      { $inc: { booked: 1 } },
      { new: true }
    );
    if (!e) {
      if (!(await Event.exists({ _id: id }))) throw new HttpError(404, 'Event not found');
      throw new HttpError(409, 'This event is full or has already started');
    }
    try {
      await Booking.create({ event: id, user: req.userId });
    } catch (err) {
      await Event.updateOne({ _id: id }, { $inc: { booked: -1 } });
      if (err.code === 11000) throw new HttpError(409, 'Already booked');
      throw err;
    }
    res.status(201).json({ event: { ...e.toJSON(), isBooked: true } });
  })
);

router.delete(
  '/events/:id/book',
  requireAuth,
  asyncH(async (req, res) => {
    if (!isDbReady() || req.userId?.startsWith('mem_')) {
      const set = memBookings.get(req.userId);
      if (set) set.delete(req.params.id);
      const e = fallback.events.find((x) => x.id === req.params.id || x._id === req.params.id) || fallback.events[0];
      return res.json({ event: { ...e, isBooked: false } });
    }
    const id = objectId(req.params.id);
    const del = await Booking.findOneAndDelete({ event: id, user: req.userId });
    if (!del) throw new HttpError(404, 'No booking found');
    const e = await Event.findByIdAndUpdate(id, { $inc: { booked: -1 } }, { new: true });
    res.json({ event: { ...e.toJSON(), isBooked: false } });
  })
);

// ---------- Profile ----------
router.get(
  '/me/activity',
  requireAuth,
  asyncH(async (req, res) => {
    if (!isDbReady() || req.userId?.startsWith('mem_')) {
      const favs = memFavs.get(req.userId) || new Set();
      const favArts = fallback.artworks
        .filter((a) => favs.has(a.id) || favs.has(a._id))
        .map((a) => ({ ...a, isFavorite: true }));

      const userBids = memUserBids.get(req.userId) || new Map();
      const bidsList = Array.from(userBids.values()).map((b) => ({
        myMax: b.myMax,
        auction: {
          ...b.auction,
          isLeading: true,
        },
      }));

      const bookings = memBookings.get(req.userId) || new Set();
      const bookingList = fallback.events
        .filter((e) => bookings.has(e.id) || bookings.has(e._id))
        .map((e) => ({ ...e, isBooked: true }));

      return res.json({
        favorites: favArts,
        bids: bidsList,
        bookings: bookingList,
      });
    }
    const user = await User.findById(req.userId).populate('favorites');
    if (!user) throw new HttpError(404, 'User not found');
    const myBids = await Bid.aggregate([
      { $match: { user: new mongoose.Types.ObjectId(req.userId) } },
      { $group: { _id: '$auction', myMax: { $max: '$amount' }, last: { $max: '$createdAt' } } },
      { $sort: { last: -1 } },
    ]);
    const auctions = await Auction.find({ _id: { $in: myBids.map((b) => b._id) } }).populate(auctionPop);
    const byId = new Map(auctions.map((a) => [a.id, a]));
    const bookings = await Booking.find({ user: user._id }).populate('event').sort({ createdAt: -1 });
    const favs = new Set(user.favorites.map((f) => f.id));
    res.json({
      favorites: user.favorites.map((a) => artView(a, favs)),
      bids: myBids
        .filter((b) => byId.has(b._id.toString()))
        .map((b) => ({ myMax: b.myMax, auction: auctionView(byId.get(b._id.toString()), req.userId) })),
      bookings: bookings.filter((b) => b.event).map((b) => ({ ...b.event.toJSON(), isBooked: true })),
    });
  })
);

module.exports = router;
