require('dotenv').config();

function required(name) {
  const v = process.env[name];
  if (!v) {
    console.error(`Missing required env var: ${name} (see .env.example)`);
    process.exit(1);
  }
  return v;
}

module.exports = {
  port: parseInt(process.env.PORT || '4000', 10),
  mongoUri: required('MONGODB_URI'),
  jwtAccessSecret: required('JWT_ACCESS_SECRET'),
  jwtRefreshSecret: required('JWT_REFRESH_SECRET'),
  accessTtl: process.env.ACCESS_TOKEN_TTL || '15m',
  refreshTtlDays: parseInt(process.env.REFRESH_TOKEN_TTL_DAYS || '30', 10),
  publicUrl: process.env.PUBLIC_URL || '',
  minBidIncrement: 100,
};
