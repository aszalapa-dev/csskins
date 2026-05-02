// ── API endpoints ─────────────────────────────────────────────────────────────
const BYMYKEL_URL             = 'https://raw.githubusercontent.com/ByMykel/CSGO-API/main/public/api/en/skins.json';
const BYMYKEL_CRATES_URL = 'https://raw.githubusercontent.com/ByMykel/CSGO-API/main/public/api/en/crates.json';
const CSFLOAT_BASE     = '/api/csfloat?limit=50&sort_by=lowest_price&type=buy_now';
const WHITE_MARKET_URL = 'https://s3.white.market/export/v1/prices/730.json';

// ── Pagination / refresh ──────────────────────────────────────────────────────
const PAGE_SIZE     = 50;
const REFRESH_MS    = 5 * 60 * 1000;
const CSFLOAT_PAGES = 20;
const USD_TO_EUR    = 0.92;

// ── Wear ──────────────────────────────────────────────────────────────────────
const WEAR_FULL = {
  'Factory New':'FN', 'Minimal Wear':'MW', 'Field-Tested':'FT',
  'Well-Worn':'WW',   'Battle-Scarred':'BS',
};
const WN = { FN:'Factory New', MW:'Minimal Wear', FT:'Field-Tested', WW:'Well-Worn', BS:'Battle-Scarred' };
const WO = ['FN','MW','FT','WW','BS'];
const WF = { FN:.03, MW:.10, FT:.22, WW:.40, BS:.55 };

// ── Labels ────────────────────────────────────────────────────────────────────
const RARITY_LABELS = { covert:'Covert', classified:'Classified', restricted:'Restricted', milspec:'Mil-Spec', industrial:'Industrial', consumer:'Consumer' };
const RARITY_RANK   = { covert:6, classified:5, restricted:4, milspec:3, industrial:2, consumer:1 };
const CAT_LABELS    = { knife:'Knives', glove:'Gloves', rifle:'Rifles', pistol:'Pistols', smg:'SMGs', sniper:'Snipers', shotgun:'Shotguns' };

// ── Float zones ───────────────────────────────────────────────────────────────
const FLOAT_ZONES = [
  { wear:'FN', min:0,    max:0.07 },
  { wear:'MW', min:0.07, max:0.15 },
  { wear:'FT', min:0.15, max:0.38 },
  { wear:'WW', min:0.38, max:0.45 },
  { wear:'BS', min:0.45, max:1.00 },
];
const ZONE_COLORS = { FN:'#00d882', MW:'#7dc84e', FT:'#ffe760', WW:'#f09832', BS:'#eb4b4b' };
const GRAY_ZONE   = '#2a3040';

// ── Category / navigation definitions ────────────────────────────────────────
const CAT_DEFS = [
  { id:'rifle',  label:'Rifles',  accent:'#ff4444', emoji:'🔫', desc:'Assault rifles',
    weapons:['AK-47','AUG','FAMAS','Galil AR','M4A1-S','M4A4','SG 553'] },
  { id:'sniper', label:'Snipers', accent:'#4488ff', emoji:'🎯', desc:'Precision rifles',
    weapons:['AWP','G3SG1','SCAR-20','SSG 08'] },
  { id:'pistol', label:'Pistols', accent:'#44ff88', emoji:'🔫', desc:'Secondary handguns',
    weapons:['CZ75-Auto','Desert Eagle','Dual Berettas','Five-SeveN','Glock-18','P2000','P250','R8 Revolver','Tec-9','USP-S'] },
  { id:'smg',    label:'SMGs',    accent:'#ffaa44', emoji:'🔫', desc:'Submachine guns',
    weapons:['MAC-10','MP5-SD','MP7','MP9','P90','PP-Bizon','UMP-45'] },
  { id:'knife',  label:'Knives',  accent:'#aa44ff', emoji:'🗡', desc:'Premium blades & special items',
    weapons:['Bayonet','Bowie Knife','Butterfly Knife','Classic Knife','Falchion Knife','Flip Knife','Gut Knife','Huntsman Knife','Karambit','Kukri Knife','M9 Bayonet','Navaja Knife','Nomad Knife','Paracord Knife','Shadow Daggers','Skeleton Knife','Stiletto Knife','Survival Knife','Talon Knife','Ursus Knife'] },
  { id:'glove',  label:'Gloves',  accent:'#44ffff', emoji:'🧤', desc:'Premium hand wraps & gloves',
    weapons:['Bloodhound Gloves','Broken Fang Gloves','Driver Gloves','Hand Wraps','Hydra Gloves','Moto Gloves','Specialist Gloves','Sport Gloves'] },
];

const NAV_CATS = [
  { id:'rifle',  label:'Rifles',  weapons:['AK-47','AUG','FAMAS','Galil AR','M4A1-S','M4A4','SG 553'] },
  { id:'sniper', label:'Snipers', weapons:['AWP','G3SG1','SCAR-20','SSG 08'] },
  { id:'pistol', label:'Pistols', weapons:['CZ75-Auto','Desert Eagle','Dual Berettas','Five-SeveN','Glock-18','P2000','P250','R8 Revolver','Tec-9','USP-S'] },
  { id:'smg',    label:'SMGs',    weapons:['MAC-10','MP5-SD','MP7','MP9','P90','PP-Bizon','UMP-45'] },
  { id:'knife',  label:'Knives',  weapons:['Bayonet','Bowie Knife','Butterfly Knife','Classic Knife','Falchion Knife','Flip Knife','Gut Knife','Huntsman Knife','Karambit','Kukri Knife','M9 Bayonet','Navaja Knife','Nomad Knife','Paracord Knife','Shadow Daggers','Skeleton Knife','Stiletto Knife','Survival Knife','Talon Knife','Ursus Knife'] },
  { id:'glove',  label:'Gloves',  weapons:['Bloodhound Gloves','Broken Fang Gloves','Driver Gloves','Hand Wraps','Hydra Gloves','Moto Gloves','Specialist Gloves','Sport Gloves'] },
];

const CAT_BY_ID = Object.fromEntries([...NAV_CATS, ...CAT_DEFS].map(c => [c.id, c]));

const CASES_NAV = [
  'Bravo Case','Chroma Case','Chroma 2 Case','Chroma 3 Case',
  'CS20 Case','Dreams & Nightmares Case','Falchion Case','Fracture Case',
  'Glove Case','Horizon Case','Huntsman Weapon Case','Kilowatt Case',
  'Operation Bravo Case','Operation Riptide Case','Recoil Case',
  'Revolution Case','Revolver Case','Shadow Case','Snakebite Case',
  'Spectrum Case','Spectrum 2 Case','Winter Offensive Weapon Case',
];

// ── Pure utility functions ────────────────────────────────────────────────────

function rarityClass(name) {
  const n = (name || '').toLowerCase();
  if (n.includes('covert') || n.includes('extraordinary') || n.includes('contraband')) return 'covert';
  if (n.includes('classified')) return 'classified';
  if (n.includes('restricted')) return 'restricted';
  return 'milspec';
}

function getCategory(weapon) {
  if (/knife|karambit|bayonet|daggers|stiletto|ursus|navaja|talon|paracord|survival|nomad|skeleton|falchion|gut |flip |shadow/i.test(weapon)) return 'knife';
  if (/gloves|wraps/i.test(weapon)) return 'glove';
  if (/awp|ssg 08|scar-20|g3sg1/i.test(weapon)) return 'sniper';
  if (/ak-47|m4a[14]|famas|galil|aug|sg 553|m249|negev/i.test(weapon)) return 'rifle';
  if (/glock|usp|p250|desert eagle|five-seven|tec-9|cz75|berettas|p2000|r8/i.test(weapon)) return 'pistol';
  if (/mp[579]|ump|p90|pp-bizon|mac-10/i.test(weapon)) return 'smg';
  return 'rifle';
}

function formatEur(n) {
  if (!n || n <= 0) return '—';
  return n >= 1000 ? '€' + Math.round(n).toLocaleString('de-DE') : '€' + n.toFixed(2);
}

function floatToWear(f) {
  for (const z of FLOAT_ZONES) if (f >= z.min && f < z.max) return z.wear;
  return f >= 0.45 ? 'BS' : 'FN';
}

function pageRange(cur, total) {
  if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1);
  if (cur <= 4)         return [1, 2, 3, 4, 5, '…', total];
  if (cur >= total - 3) return [1, '…', total - 4, total - 3, total - 2, total - 1, total];
  return [1, '…', cur - 1, cur, cur + 1, '…', total];
}

function escH(s) { return String(s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }
function escA(s) { return String(s||'').replace(/"/g,'&quot;').replace(/'/g,'&#39;'); }
const escHtml = escH;
