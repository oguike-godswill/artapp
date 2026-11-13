const fs = require('fs');
const path = require('path');

const sampleRate = 44100;
const durationSec = 35;
const totalSamples = sampleRate * durationSec;
const buffer = Buffer.alloc(44 + totalSamples * 2);

// WAV Header
buffer.write('RIFF', 0);
buffer.writeUInt32LE(36 + totalSamples * 2, 4);
buffer.write('WAVE', 8);
buffer.write('fmt ', 12);
buffer.writeUInt32LE(16, 16);
buffer.writeUInt16LE(1, 20);
buffer.writeUInt16LE(1, 22);
buffer.writeUInt32LE(sampleRate, 24);
buffer.writeUInt32LE(sampleRate * 2, 28);
buffer.writeUInt16LE(2, 32);
buffer.writeUInt16LE(16, 34);
buffer.write('data', 36);
buffer.writeUInt32LE(totalSamples * 2, 40);

// Gentle Solis warm acoustic chords
const chords = [
  [220.0, 277.18, 329.63, 440.0],
  [196.0, 246.94, 293.66, 392.0],
  [164.81, 220.0, 261.63, 329.63],
  [220.0, 261.63, 329.63, 440.0],
];

for (let i = 0; i < totalSamples; i++) {
  const t = i / sampleRate;
  const chordIdx = Math.floor(t / 8.75) % chords.length;
  const chord = chords[chordIdx];

  let sample = 0;
  for (let c = 0; c < chord.length; c++) {
    const freq = chord[c];
    const noteTime = t % 4.375;
    const env = Math.exp(-noteTime * 0.9) * 0.22;
    sample += Math.sin(2 * Math.PI * freq * t) * env;
    sample += Math.sin(4 * Math.PI * freq * t) * env * 0.35;
    sample += Math.sin(6 * Math.PI * freq * t) * env * 0.12;
  }

  const masterFade = Math.min(t / 1.5, 1.0) * Math.min((durationSec - t) / 2.0, 1.0);
  sample *= masterFade;

  const intSample = Math.max(-32767, Math.min(32767, Math.round(sample * 32767)));
  buffer.writeInt16LE(intSample, 44 + i * 2);
}

const outDir = path.join(__dirname, '..', 'public', 'art');
if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
const outPath = path.join(outDir, 'guide.wav');
fs.writeFileSync(outPath, buffer);
console.log('Audio track created successfully at:', outPath, 'Bytes:', buffer.length);
