const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');
const config = require('./config');
const { Artwork, Auction, Exhibition, Event, Bid } = require('./models');

const artDir = path.join(__dirname, '..', 'public', 'art');
const files = fs.existsSync(artDir) ? fs.readdirSync(artDir) : [];
const img = (base) => {
  const f = files.find((x) => path.parse(x).name === base);
  if (!f) console.warn(`  ! missing image for ${base}`);
  return `/art/${f || base + '.jpg'}`;
};

const day = 864e5;
const hr = 36e5;
function at(daysFromToday, hour) {
  const d = new Date();
  d.setHours(hour, 0, 0, 0);
  return new Date(d.getTime() + daysFromToday * day);
}

(async () => {
  await mongoose.connect(config.mongoUri);
  console.log('Seeding…');
  await Promise.all([Artwork.deleteMany({}), Auction.deleteMany({}), Exhibition.deleteMany({}), Event.deleteMany({}), Bid.deleteMany({})]);

  const arts = await Artwork.insertMany([
    { title: 'Fan Palm Crossing', artist: 'Elena Marwa', medium: 'Oil on canvas', year: 2024, dimensions: '90 × 70 cm', image: img('fan_palm_crossing'), printPrice: 210, editionSize: 250, series: 'Water series', featured: true, saves: 61,
      description: 'A lone ferryman poles a raft crowned with fan palms across a river glowing at dusk.' },
    { title: 'Blue Door Hibiscus', artist: 'Rafaela Quintero', medium: 'Oil', year: 2023, dimensions: '60 × 45 cm', image: img('blue_door_hibiscus'), printPrice: 180, editionSize: 250, series: 'Water series', saves: 43,
      description: 'A hibiscus in full voice before the blue shutters of a coastal house, painted in thick impasto.' },
    { title: 'Still Water, Koi', artist: 'Tomás Adeyemi', medium: 'Gouache', year: 2024, dimensions: '50 × 40 cm', image: img('still_water_koi'), printPrice: 150, editionSize: 200, series: 'Water series', saves: 38,
      description: 'Seen from above, a small boat drifts through lily pads while koi flicker beneath.' },
    { title: 'Golden Hour Porch', artist: 'Amara Diallo', medium: 'Acrylic', year: 2022, dimensions: '70 × 50 cm', image: img('golden_hour_porch'), printPrice: 90, editionSize: 300, saves: 27,
      description: 'Ripening plantains hang against a cobalt wall as the evening light turns everything to honey.' },
    { title: 'The Teal Garden', artist: 'Nia Okafor', medium: 'Gouache on paper', year: 2023, dimensions: '40 × 30 cm', image: img('teal_garden'), printPrice: 95, editionSize: 300, saves: 52,
      description: 'A dreamlike walk through cypress and citrus-coloured hedges under a low yellow sun.' },
    { title: 'Whispers', artist: 'Zawadi Mensah', medium: 'Mixed media', year: 2024, dimensions: '80 × 60 cm', image: img('whispers'), printPrice: 160, editionSize: 150, saves: 70,
      description: 'Two women share a secret, their patterned scarves speaking as loudly as their eyes.' },
    { title: 'Woven Crown', artist: 'Kofi Asante', medium: 'Oil on linen', year: 2024, dimensions: '75 × 55 cm', image: img('woven_hat'), printPrice: 140, editionSize: 200, saves: 33,
      description: 'A figure in a hand-woven palm hat stands before a burning orange sun.' },
    { title: 'Baskets of Bolga', artist: 'Ama Owusu', medium: 'Photograph, giclée', year: 2021, dimensions: '60 × 90 cm', image: img('evening_of_weaving'), printPrice: 80, editionSize: 500, saves: 19,
      description: 'Geometric rhythms of Bolgatanga baskets stacked in the afternoon market.' },
  ]);
  const A = Object.fromEntries(arts.map((a) => [a.title, a]));

  await Auction.insertMany([
    { artwork: A['Fan Palm Crossing']._id, lotNumber: 14, startingBid: 2500, currentBid: 4800, bidCount: 18, endsAt: new Date(Date.now() + 2 * day + 14 * hr) },
    { artwork: A['Blue Door Hibiscus']._id, lotNumber: 21, startingBid: 1800, currentBid: 3200, bidCount: 12, endsAt: new Date(Date.now() + 2 * day + 14 * hr) },
    { artwork: A['Still Water, Koi']._id, lotNumber: 22, startingBid: 1200, currentBid: 2150, bidCount: 9, endsAt: new Date(Date.now() + 5 * day + 3 * hr) },
    { artwork: A['Golden Hour Porch']._id, lotNumber: 23, startingBid: 900, currentBid: 1400, bidCount: 6, endsAt: new Date(Date.now() + 6 * day + 8 * hr) },
    { artwork: A['Whispers']._id, lotNumber: 24, startingBid: 3000, currentBid: 3000, bidCount: 0, endsAt: new Date(Date.now() + 8 * day) },
  ]);

  await Exhibition.create({ title: 'Colour, carried by water', gallery: 'Gallery 1', workCount: 12, startsAt: new Date(Date.now() - 10 * day), endsAt: new Date(Date.now() + 60 * day) });

  await Event.insertMany([
    { title: 'Artist Talk: Whispers', venue: 'Auditorium', durationMin: 60, price: 10, startsAt: at(1, 14), image: img('whispers'), description: 'Zawadi Mensah on pattern, gossip and the politics of the headscarf.', capacity: 120 },
    { title: 'Evening of Weaving', venue: 'Gallery 3', durationMin: 90, price: 25, membersFree: true, startsAt: at(1, 19), image: img('evening_of_weaving'), description: 'A hands-on evening with master weavers from Bolgatanga.', capacity: 40 },
    { title: 'Curator Walk: Water series', venue: 'Gallery 1', durationMin: 45, price: 0, startsAt: at(3, 11), image: img('still_water_koi'), description: 'A guided walk through the Water series.', capacity: 25 },
    { title: 'Tour: The Teal Garden', venue: 'Sculpture Garden', durationMin: 60, price: 15, startsAt: at(6, 10), image: img('teal_garden'), description: 'An outdoor tour inspired by Nia Okafor’s gardens.', capacity: 30 },
    { title: 'Print Studio Open Day', venue: 'Print Studio', durationMin: 240, price: 0, startsAt: at(15, 10), image: img('woven_hat'), description: 'See the edition printing process and meet the printmakers.', capacity: 200 },
    { title: 'Late at Solis', venue: 'Main Hall', durationMin: 180, price: 20, membersFree: true, startsAt: at(20, 19), image: img('golden_hour_porch'), description: 'Music, drinks and the galleries after dark.', capacity: 300 },
  ]);

  console.log('Done.');
  await mongoose.disconnect();
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
