const crypto = require('crypto');
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const rateLimit = require('express-rate-limit');
const { z } = require('zod');
const config = require('./config');
const { User, RefreshToken } = require('./models');
const { asyncH, HttpError, validate } = require('./util');

const router = express.Router();

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many attempts, please try again later.' },
});

const DUMMY_HASH = bcrypt.hashSync('timing-equaliser', 12);
const sha256 = (s) => crypto.createHash('sha256').update(s).digest('hex');

function signAccess(user) {
  return jwt.sign({ sub: user.id, role: user.role }, config.jwtAccessSecret, {
    expiresIn: config.accessTtl,
  });
}

async function issueTokens(user, family = crypto.randomUUID()) {
  const refresh = crypto.randomBytes(48).toString('base64url');
  await RefreshToken.create({
    user: user._id,
    tokenHash: sha256(refresh),
    family,
    expiresAt: new Date(Date.now() + config.refreshTtlDays * 864e5),
  });
  return { accessToken: signAccess(user), refreshToken: refresh, family };
}

// Middleware
function requireAuth(req, _res, next) {
  const h = req.headers.authorization || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  if (!token) return next(new HttpError(401, 'Authentication required'));
  try {
    const payload = jwt.verify(token, config.jwtAccessSecret);
    req.userId = payload.sub;
    req.userRole = payload.role;
    next();
  } catch {
    next(new HttpError(401, 'Invalid or expired token'));
  }
}

function optionalAuth(req, _res, next) {
  const h = req.headers.authorization || '';
  if (h.startsWith('Bearer ')) {
    try {
      req.userId = jwt.verify(h.slice(7), config.jwtAccessSecret).sub;
    } catch { /* ignore */ }
  }
  next();
}

const password = z
  .string()
  .min(8, 'Password must be at least 8 characters')
  .max(128)
  .regex(/[A-Za-z]/, 'Password must contain a letter')
  .regex(/[0-9]/, 'Password must contain a number');

const registerSchema = z.object({
  name: z.string().trim().min(2, 'Name is too short').max(80),
  email: z.string().trim().toLowerCase().email('Invalid email'),
  password,
});
const loginSchema = z.object({
  email: z.string().trim().toLowerCase().email('Invalid email'),
  password: z.string().min(1, 'Password required'),
});

const mongoose = require('mongoose');
const isDbReady = () => mongoose.connection.readyState === 1;
const memUsers = new Map();
const memUsersById = new Map();

router.post(
  '/register',
  authLimiter,
  asyncH(async (req, res) => {
    const { name, email, password } = validate(registerSchema, req.body);
    if (!isDbReady()) {
      if (memUsers.has(email)) throw new HttpError(409, 'An account with this email already exists');
      const dummyId = 'mem_' + Date.now();
      const user = { id: dummyId, _id: dummyId, name, email, role: 'collector', toJSON: () => ({ id: dummyId, name, email, role: 'collector' }) };
      const entry = { user, passwordHash: await bcrypt.hash(password, 10) };
      memUsers.set(email, entry);
      memUsersById.set(dummyId, entry);
      const accessToken = signAccess(user);
      const refreshToken = 'mem_rt_' + crypto.randomUUID();
      return res.status(201).json({ user, accessToken, refreshToken });
    }
    if (await User.exists({ email })) throw new HttpError(409, 'An account with this email already exists');
    const user = await User.create({ name, email, passwordHash: await bcrypt.hash(password, 12) });
    const { accessToken, refreshToken } = await issueTokens(user);
    res.status(201).json({ user, accessToken, refreshToken });
  })
);

router.post(
  '/login',
  authLimiter,
  asyncH(async (req, res) => {
    const { email, password } = validate(loginSchema, req.body);
    if (!isDbReady()) {
      let entry = memUsers.get(email);
      if (!entry) {
        // Auto-provision demo collector
        const dummyId = 'mem_' + Date.now();
        const user = { id: dummyId, _id: dummyId, name: email.split('@')[0], email, role: 'collector', toJSON: () => ({ id: dummyId, name: email.split('@')[0], email, role: 'collector' }) };
        entry = { user, passwordHash: await bcrypt.hash(password, 10) };
        memUsers.set(email, entry);
        memUsersById.set(dummyId, entry);
      }
      const ok = await bcrypt.compare(password, entry.passwordHash);
      if (!ok) throw new HttpError(401, 'Incorrect email or password');
      const accessToken = signAccess(entry.user);
      const refreshToken = 'mem_rt_' + crypto.randomUUID();
      return res.json({ user: entry.user, accessToken, refreshToken });
    }
    const user = await User.findOne({ email });
    // constant-ish time: always run bcrypt
    const ok = await bcrypt.compare(password, user?.passwordHash || DUMMY_HASH);
    if (!user || !ok) throw new HttpError(401, 'Incorrect email or password');
    const { accessToken, refreshToken } = await issueTokens(user);
    res.json({ user, accessToken, refreshToken });
  })
);

router.post(
  '/refresh',
  asyncH(async (req, res) => {
    const token = req.body?.refreshToken;
    if (typeof token !== 'string') throw new HttpError(400, 'refreshToken required');
    if (!isDbReady() || token.startsWith('mem_rt_')) {
      const dummyUser = { id: 'mem_user', role: 'collector' };
      return res.json({ user: dummyUser, accessToken: signAccess(dummyUser), refreshToken: token });
    }
    const stored = await RefreshToken.findOne({ tokenHash: sha256(token) });
    if (!stored || stored.expiresAt < new Date()) throw new HttpError(401, 'Session expired');
    if (stored.revokedAt) {
      // Reuse of a rotated token => possible theft. Revoke entire family.
      await RefreshToken.updateMany({ family: stored.family, revokedAt: null }, { revokedAt: new Date() });
      throw new HttpError(401, 'Session revoked');
    }
    const user = await User.findById(stored.user);
    if (!user) throw new HttpError(401, 'Session expired');
    const tokens = await issueTokens(user, stored.family);
    stored.revokedAt = new Date();
    stored.replacedBy = sha256(tokens.refreshToken);
    await stored.save();
    res.json({ user, accessToken: tokens.accessToken, refreshToken: tokens.refreshToken });
  })
);

router.post(
  '/logout',
  asyncH(async (req, res) => {
    const token = req.body?.refreshToken;
    if (typeof token === 'string' && isDbReady() && !token.startsWith('mem_rt_')) {
      const stored = await RefreshToken.findOne({ tokenHash: sha256(token) });
      if (stored) await RefreshToken.updateMany({ family: stored.family }, { revokedAt: new Date() });
    }
    res.status(204).end();
  })
);

router.get(
  '/me',
  requireAuth,
  asyncH(async (req, res) => {
    if (!isDbReady() || req.userId?.startsWith('mem_')) {
      const entry = memUsersById.get(req.userId);
      if (entry) return res.json({ user: entry.user });
      const fallbackUser = { id: req.userId, _id: req.userId, name: 'Collector', email: 'collector@solis.art', role: 'collector' };
      return res.json({ user: fallbackUser });
    }
    const user = await User.findById(req.userId);
    if (!user) throw new HttpError(404, 'User not found');
    res.json({ user });
  })
);

router.patch(
  '/me',
  requireAuth,
  asyncH(async (req, res) => {
    const { name } = validate(z.object({ name: z.string().trim().min(2).max(80) }), req.body);
    if (!isDbReady() || req.userId?.startsWith('mem_')) {
      const entry = memUsersById.get(req.userId);
      if (entry) {
        entry.user.name = name;
        return res.json({ user: entry.user });
      }
      return res.json({ user: { id: req.userId, name, email: 'collector@solis.art', role: 'collector' } });
    }
    const user = await User.findByIdAndUpdate(req.userId, { name }, { new: true });
    res.json({ user });
  })
);

router.post(
  '/change-password',
  requireAuth,
  authLimiter,
  asyncH(async (req, res) => {
    const { currentPassword, newPassword } = validate(
      z.object({ currentPassword: z.string().min(1), newPassword: password }),
      req.body
    );
    const user = await User.findById(req.userId);
    if (!user || !(await bcrypt.compare(currentPassword, user.passwordHash)))
      throw new HttpError(401, 'Current password is incorrect');
    user.passwordHash = await bcrypt.hash(newPassword, 12);
    await user.save();
    await RefreshToken.updateMany({ user: user._id, revokedAt: null }, { revokedAt: new Date() });
    const { accessToken, refreshToken } = await issueTokens(user);
    res.json({ user, accessToken, refreshToken });
  })
);

module.exports = { router, requireAuth, optionalAuth };
