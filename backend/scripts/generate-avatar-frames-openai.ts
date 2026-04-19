/**
 * Tạo PNG khung avatar (tràn viền) qua OpenAI Images (DALL·E 3) + khoét lỗ tròn khớp layout app.
 *
 * Cần OPENAI_API_KEY (đặt trong backend/.env hoặc export trước khi chạy).
 *
 *   cd backend && npx ts-node -r tsconfig-paths/register scripts/generate-avatar-frames-openai.ts
 *   npx ts-node -r tsconfig-paths/register scripts/generate-avatar-frames-openai.ts --dry-run
 *   npx ts-node -r tsconfig-paths/register scripts/generate-avatar-frames-openai.ts --only=af_01,af_02
 */

import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import OpenAI from 'openai';
/** CommonJS callable export — tránh `import default` khi tsconfig không bật esModuleInterop. */
import sharp = require('sharp');
import { AVATAR_FRAMES_CATALOG } from '../src/avatar-frames/avatar-frames.catalog';

const SIZE = 1024;
const OUT_DIR = path.join(__dirname, '../../mobile/assets/avatar_frames');

function gradientOuter(inner: number, tier: number): number {
  const t = Math.min(20, Math.max(1, tier));
  const ring = 1.4 + (t / 20) * 3.2;
  return inner + ring * 2 + (t >= 12 ? 4.0 : 0) + (t >= 17 ? 4.0 : 0);
}

function pngSlot(inner: number, tier: number): number {
  const scale = 1.38 + tier * 0.017;
  return inner * Math.min(1.88, Math.max(1.32, scale));
}

/** Khớp mobile/lib/theme/widgets/avatar_frame_ring.dart */
function avatarFrameOuterDiameter(inner: number, tier: number): number {
  return Math.max(gradientOuter(inner, tier), pngSlot(inner, tier));
}

/** Bán kính lỗ mặt (pixel) trên ảnh vuông SIZE, để khớp inner/outer trong app. */
function holeRadiusPx(tier: number): number {
  const inner = 100;
  const outer = avatarFrameOuterDiameter(inner, tier);
  const holeDiameterPx = SIZE * (inner / outer);
  return holeDiameterPx / 2;
}

function overflowInstructions(tier: number): string {
  if (tier <= 3) {
    return 'Very subtle thin ring; decorations stay almost inside the circular silhouette; minimal or no overflow past the circle edge.';
  }
  if (tier <= 7) {
    return 'Modest ornaments: small gems or soft glow; only tiny accents may slightly break past the rim.';
  }
  if (tier <= 11) {
    return 'Clear magical glow, small stars or sparks; ornaments visibly extend a short distance outside the circular rim.';
  }
  if (tier <= 15) {
    return 'Elaborate filigree, small wings or horns above the circle, metallic shine; strong decorative overflow beyond the circle.';
  }
  if (tier <= 18) {
    return 'Luxury jeweled frame with large wings or crown elements, heavy bloom; dramatic asymmetrical overflow far outside the circle.';
  }
  return 'Legendary ultra-premium: massive fantasy wings or dragon coils, crystals, intense particle glow, extreme ornamental overflow bursting far beyond the circle; maximum detail and layers.';
}

const THEME_EN: Record<string, string> = {
  af_01: 'minimal clean white and silver thin ring, soft matte',
  af_02: 'pale fog gray mist, soft blur halo',
  af_03: 'subtle purple smoke gradient accents',
  af_04: 'teal jade gemstone vibe, fresh cool tones',
  af_05: 'pastel pink gradient, gentle cute glow',
  af_06: 'antique gold bronze classical trim',
  af_07: 'deep emerald double-layer green border',
  af_08: 'neon purple magenta electric glow',
  af_09: 'icy cyan frost crystals, cold blue highlights',
  af_10: 'ember orange-red heat energy streaks',
  af_11: 'star motifs and sparkles, cosmic dust',
  af_12: 'flowing wave patterns around the ring',
  af_13: 'lightning bolts and brushed steel metal',
  af_14: 'crescent moon and silver lunar rings',
  af_15: 'intricate oriental antique engraved patterns',
  af_16: 'radiant golden holy light rays and halo',
  af_17: 'multi-layer crystal nebula gradients',
  af_18: 'royal jewels, gems, dramatic shadows and shine',
  af_19: 'coiling eastern dragon scales and clouds',
  af_20: 'supreme nine-heavens mythic splendor, ultimate rarity, richest materials',
};

function buildPrompt(frame: (typeof AVATAR_FRAMES_CATALOG)[number]): string {
  const tier = frame.tier;
  const theme = THEME_EN[frame.id] ?? 'fantasy game avatar frame';
  const overflow = overflowInstructions(tier);
  return [
    'Square 1:1 game UI asset for a mobile RPG profile picture frame overlay.',
    'Transparent background everywhere except the frame artwork.',
    'The frame is centered; leave a perfectly circular empty transparent hole in the middle for the user face photo (the hole must be clear alpha, not white).',
    'No text, no letters, no watermark, no logos.',
    `Theme: ${theme}.`,
    `Prestige tier ${tier} of 20 — higher tier means more expensive item: add more micro-detail, richer materials, stronger glow, and more dramatic "overflow" ornaments outside the circle.`,
    overflow,
    'Style: polished mobile game 2D UI art, crisp edges, subtle 3D bevel, PBR-like highlights, vibrant but not muddy.',
  ].join(' ');
}

function parseArgs(): { dryRun: boolean; only: Set<string> | null } {
  const dryRun = process.argv.includes('--dry-run');
  const onlyArg = process.argv.find((a) => a.startsWith('--only='));
  const only = onlyArg
    ? new Set(
        onlyArg
          .slice('--only='.length)
          .split(',')
          .map((s) => s.trim())
          .filter(Boolean),
      )
    : null;
  return { dryRun, only };
}

async function punchCircularHole(pngBuffer: Buffer, tier: number): Promise<Buffer> {
  const cx = SIZE / 2;
  const cy = SIZE / 2;
  const r = holeRadiusPx(tier);
  const svg = Buffer.from(
    `<svg width="${SIZE}" height="${SIZE}">
      <circle cx="${cx}" cy="${cy}" r="${r}" fill="white"/>
    </svg>`,
  );
  return sharp(pngBuffer)
    .ensureAlpha()
    .composite([{ input: svg, blend: 'dest-out' }])
    .png()
    .toBuffer();
}

async function main(): Promise<void> {
  const { dryRun, only } = parseArgs();
  const apiKey = process.env.OPENAI_API_KEY;
  if (!dryRun && !apiKey) {
    console.error('Thiếu OPENAI_API_KEY. Thêm vào backend/.env hoặc export biến môi trường.');
    process.exit(1);
  }

  const openai = apiKey ? new OpenAI({ apiKey }) : null;

  if (!fs.existsSync(OUT_DIR)) {
    fs.mkdirSync(OUT_DIR, { recursive: true });
  }

  const frames = AVATAR_FRAMES_CATALOG.filter((f) => !only || only.has(f.id));

  console.log(`Frames: ${frames.map((f) => f.id).join(', ')}`);
  if (dryRun) {
    for (const f of frames) {
      console.log('\n---', f.id, 'tier', f.tier, '---\n', buildPrompt(f));
    }
    console.log('\n[dry-run] Không gọi API.');
    return;
  }

  for (const frame of frames) {
    const prompt = buildPrompt(frame);
    const quality = frame.tier >= 14 ? 'hd' : 'standard';
    process.stdout.write(`Generating ${frame.id} (tier ${frame.tier}, ${quality})... `);
    try {
      const res = await openai!.images.generate({
        model: 'dall-e-3',
        prompt,
        n: 1,
        size: '1024x1024',
        quality,
        response_format: 'b64_json',
      });
      const b64 = res.data?.[0]?.b64_json;
      if (!b64) {
        console.log('no image data');
        continue;
      }
      const raw = Buffer.from(b64, 'base64');
      const punched = await punchCircularHole(raw, frame.tier);
      const outPath = path.join(OUT_DIR, `${frame.id}.png`);
      fs.writeFileSync(outPath, punched);
      console.log(`OK -> ${outPath}`);
    } catch (e) {
      console.log('FAIL', e instanceof Error ? e.message : e);
    }
    await new Promise((r) => setTimeout(r, 1500));
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
