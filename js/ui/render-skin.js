// Responsibility: build all HTML for the skin detail page (redesigned)

const W_BADGE_CLS = { FN:'w-fn', MW:'w-mw', FT:'w-ft', WW:'w-ww', BS:'w-bs' };

const RARITY_GLOW = {
  covert:     'rgba(235,75,75,.12)',
  classified: 'rgba(145,71,255,.10)',
  restricted: 'rgba(75,105,255,.10)',
  milspec:    'rgba(75,134,219,.08)',
};

const MP_SOURCE_META = {
  skinport:  { name: 'Skinport',  abbr: 'SP', bg: '#0d1822', color: '#f79a3f', stars: 4.6 },
  csfloat:   { name: 'CSFloat',   abbr: 'CF', bg: '#0d1520', color: '#5b8af5', stars: 4.8 },
  dmarket:   { name: 'DMarket',   abbr: 'DM', bg: '#0c1624', color: '#4a9eff', stars: 4.5 },
  shadowpay: { name: 'Shadowpay', abbr: 'SH', bg: '#0d1a14', color: '#2ecc71', stars: 4.3 },
  waxpeer:   { name: 'Waxpeer',   abbr: 'WP', bg: '#14100a', color: '#e88b34', stars: 4.4 },
  bitskins:  { name: 'BitSkins',  abbr: 'BK', bg: '#0d0d20', color: '#7b68ee', stars: 4.2 },
};

const USD_TO_EUR = 0.92;

// ─── Helpers ──────────────────────────────────────────────────────────────────
function escH(s) { return String(s ?? '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }
function escA(s) { return String(s ?? '').replace(/"/g,'&quot;'); }

function fmtPrice(n, currency) {
  if (n == null) return '—';
  return (currency === 'USD' ? '$' : '€') + n.toFixed(2);
}
function deltaStr(d, currency) {
  if (Math.abs(d) < 0.005) return '<span style="color:var(--green)">cheapest</span>';
  return '+' + fmtPrice(d, currency);
}

function floatToWear(f) {
  if (f < 0.07) return 'FN';
  if (f < 0.15) return 'MW';
  if (f < 0.38) return 'FT';
  if (f < 0.45) return 'WW';
  return 'BS';
}

// ─── Hero ─────────────────────────────────────────────────────────────────────
function buildHero(skin) {
  const catLabel  = CAT_LABELS[skin.category] || 'Skins';
  const rarLabel  = RARITY_LABELS[skin.rarity] || '';
  const wearFull  = WN[skin.wear] || skin.wear || '';
  const weaponName = skin.weaponName || skin.name || '';
  const wp   = skin.wearPrices || {};
  const vals = Object.values(wp).filter(e => e?.priceEur > 0);
  const best = vals.length ? vals.reduce((a,b) => a.priceEur<=b.priceEur ? a : b) : null;
  const minFloat = skin.minFloat ?? 0.00;
  const maxFloat = skin.maxFloat ?? 1.00;
  const glow = RARITY_GLOW[skin.rarity] || 'rgba(255,255,255,.04)';

  const hasST = skin.stattrak === true || WO.some(w => (skin.stWearPrices||{})[w]);
  const hasSV = skin.souvenir === true || WO.some(w => (skin.svWearPrices||{})[w]);
  const marketCount = Object.keys(MP_SOURCE_META).length;

  return `
<div class="hero">
  <div class="hero-inner">
    <div>
      <div class="hero-meta">
        <span class="kicker">${escH(catLabel)}<span class="dot"></span>${escH(weaponName)}<span class="dot"></span>${escH(rarLabel)}</span>
      </div>
      <h1 class="skin-h1">${escH(weaponName)}${skin.variant ? ' <span class="pipe">|</span> <span class="variant">' + escH(skin.variant) + '</span>' : ''}</h1>
      <div class="hero-tags">
        <span class="hero-tag rar-${skin.rarity}"><span class="tag-dot"></span>${escH(rarLabel)}</span>
        <span class="hero-tag">${escH(wearFull)}</span>
        ${skin.collection ? '<span class="hero-tag">' + escH(skin.collection) + '</span>' : ''}
        ${hasST ? '<span class="hero-tag" style="color:var(--st);border-color:rgba(255,140,0,.3);background:rgba(255,140,0,.08)">StatTrak™</span>' : ''}
        <span class="hero-tag">CS2</span>
      </div>
      <div class="hero-stats">
        <div class="hero-stat">
          <div class="hero-stat-l">From</div>
          <div class="hero-stat-v green" id="heroFromPrice">${best ? escH(best.priceStr) : '—'}</div>
          <div class="hero-stat-s">${marketCount} markets</div>
        </div>
        <div class="hero-stat">
          <div class="hero-stat-l">Float range</div>
          <div class="hero-stat-v">${minFloat.toFixed(2)}–${maxFloat.toFixed(2)}</div>
          <div class="hero-stat-s">5 wear tiers</div>
        </div>
        <div class="hero-stat">
          <div class="hero-stat-l">Collection</div>
          <div class="hero-stat-v accent" style="font-size:13px;font-weight:700">${escH(skin.collection || '—')}</div>
          <div class="hero-stat-s">${escH(wearFull)}</div>
        </div>
      </div>
    </div>
    <div class="hero-img-wrap">
      <div class="hero-img-bg" style="background:radial-gradient(ellipse at 50% 50%, ${glow}, transparent 65%)"></div>
      <img class="hero-img-real" src="${escA(skin.image)}" alt="${escA(weaponName + (skin.variant ? ' | '+skin.variant : ''))}" onerror="this.style.opacity='.06'" />
      <div class="hero-img-actions" id="imgBtns">
        <button class="hero-img-btn" onclick="toggleMirror()">↺ Flip</button>
        <button class="hero-img-btn" id="btn3d" onclick="toggle3DView()">⬡ 3D</button>
        <button class="hero-img-btn" onclick="copyURL()">🔗 Share</button>
      </div>
    </div>
  </div>
</div>`;
}

// ─── Viewer card ──────────────────────────────────────────────────────────────
function buildViewerCard(skin) {
  const floatNum = parseFloat(skin.float) || WF[skin.wear] || 0.15;
  const floatStr = skin.float || floatNum.toFixed(4);
  const wearFull = WN[skin.wear] || skin.wear || '';
  const weaponName = skin.weaponName || skin.name || '';
  return `
<div class="viewer-card">
  <div class="viewer-tabs" id="viewTabs">
    <button class="viewer-tab active" data-tab="wear" onclick="setViewTab('wear')">Wear preview</button>
    <button class="viewer-tab" data-tab="3d" onclick="setViewTab('3d')">3D View</button>
    <button class="viewer-tab" data-tab="inspect" onclick="setViewTab('inspect')">Inspect</button>
    <div class="viewer-tab-actions">
      <span class="viewer-tab-pill"><span class="live-dot"></span>Live</span>
    </div>
  </div>
  <div class="viewer-stage" id="viewerStage">
    <img id="skinImg"
         src="${escA(skin.image)}"
         alt="${escA(weaponName + (skin.variant ? ' | '+skin.variant : ''))}"
         onerror="this.style.opacity='.08'"
         onclick="toggleZoom()" />
    <div id="viewer3d" class="viewer3d" style="display:none">
      <div class="vd-drop" id="viewerDrop">
        <div class="vd-icon">⬡</div>
        <div class="vd-title">CS2 3D Viewer</div>
        <div class="vd-hint">Drop a <strong>.glb</strong> weapon model here</div>
        <div class="vd-sub">Also drop textures: albedo · wear_mask</div>
      </div>
      <canvas id="viewer3dCanvas" style="display:none"></canvas>
    </div>
    <div id="inspectFrame" class="inspect-frame"></div>
    <div class="viewer-actions" style="position:absolute;top:12px;right:12px;display:flex;gap:5px;z-index:2">
      <button class="va-btn" onclick="toggleZoom()">+ Zoom</button>
    </div>
  </div>
  <div class="viewer-foot">
    <div>Float: <strong id="floatDisplay">${escH(floatStr)}</strong> · <span id="floatWearTxt">${escH(wearFull)}</span></div>
    <div style="display:flex;align-items:center;gap:5px;font-size:10px;color:var(--muted2)">
      <span class="live-dot" style="width:5px;height:5px;box-shadow:none"></span>white.market · live
    </div>
  </div>
</div>`;
}

// ─── Float card ───────────────────────────────────────────────────────────────
function buildFloatCard(skin) {
  const floatNum = parseFloat(skin.float) || WF[skin.wear] || 0.15;
  const floatStr = skin.float || floatNum.toFixed(4);
  const wear     = floatToWear(floatNum);
  const wearFull = WN[wear] || wear;
  const minFloat = skin.minFloat ?? 0.00;
  const maxFloat = skin.maxFloat ?? 1.00;
  return `
<div class="float-card">
  <div class="float-card-hd">
    <span class="float-card-title">Float Value</span>
    <span class="float-card-range">range ${minFloat.toFixed(2)}–${maxFloat.toFixed(2)}</span>
  </div>
  <div class="float-row1">
    <div class="float-num-wrap">
      <div class="float-num" id="floatNum">${escH(floatStr)}</div>
      <div class="float-wear-txt" id="floatWearName">${escH(wearFull)}</div>
    </div>
    <span class="float-wear-pill w-${wear}" id="floatWearPill">${wear}</span>
  </div>
  <div class="float-track-wrap">
    <div class="float-track" id="floatTrack"></div>
    <input type="range" id="floatSlider" class="float-range"
           min="0" max="1" step="0.0001" value="${floatNum}" />
  </div>
  <div class="float-ticks">
    <span>FN</span><span>MW</span><span>FT</span><span>WW</span><span>BS</span>
  </div>
</div>`;
}

// ─── Wear grid (5-col) ────────────────────────────────────────────────────────
function buildWearGrid(skin) {
  const hasST = skin.stattrak === true || WO.some(w => (skin.stWearPrices||{})[w]);
  const hasSV = skin.souvenir === true || WO.some(w => (skin.svWearPrices||{})[w]);

  return `
<div class="card" id="wearPricesCard">
  <div class="card-hd">
    <div class="card-hd-title"><span class="live-dot"></span>Prices by wear</div>
    <div class="card-hd-meta">white.market · live</div>
  </div>
  ${(hasST || hasSV) ? `
  <div class="variant-tabs" id="variantTabs">
    <button class="variant-tab active" data-variant="normal" onclick="setVariant('normal')">Normal</button>
    ${hasST ? '<button class="variant-tab st" data-variant="st" onclick="setVariant(\'st\')">StatTrak™</button>' : ''}
    ${hasSV ? '<button class="variant-tab sv" data-variant="sv" onclick="setVariant(\'sv\')">Souvenir</button>' : ''}
  </div>` : ''}
  <div id="wearGridBody">${buildWearCells(skin, 'normal')}</div>
</div>`;
}

function buildWearCells(skin, variant) {
  const map = variant === 'st' ? (skin.stWearPrices || {})
            : variant === 'sv' ? (skin.svWearPrices || {})
            : (skin.wearPrices || {});
  const have = WO.filter(w => map[w]);
  const best = have.length ? have.reduce((a,b) => map[a].priceEur <= map[b].priceEur ? a : b) : null;

  const wearColors = {
    FN: { bg: 'rgba(0,216,130,.14)',  c: '#00d882' },
    MW: { bg: 'rgba(125,200,78,.14)', c: '#7dc84e' },
    FT: { bg: 'rgba(255,231,96,.14)', c: '#d4bd30' },
    WW: { bg: 'rgba(240,152,50,.14)', c: '#f09832' },
    BS: { bg: 'rgba(235,75,75,.14)',  c: '#eb4b4b' },
  };

  return `<div class="wear-grid">${WO.map(w => {
    const p = map[w];
    if (!p) return `
      <div class="wear-cell unavail">
        <span class="wear-cell-badge" style="background:rgba(255,255,255,.05);color:var(--muted2)">${w}</span>
        <span class="wear-cell-name">${WN[w]}</span>
        <span class="wear-cell-price">—</span>
      </div>`;
    const isBest = w === best;
    const wc = wearColors[w];
    return `
      <a class="wear-cell${isBest ? ' wc-best' : ''}" href="${escA(p.url)}" target="_blank" rel="noopener">
        <span class="wear-cell-badge" style="background:${wc.bg};color:${wc.c}">${w}</span>
        <span class="wear-cell-name">${WN[w]}</span>
        <span class="wear-cell-price">${escH(p.priceStr)}</span>
        ${isBest ? '<span class="wear-cell-best-tag">Best</span>' : ''}
      </a>`;
  }).join('')}</div>`;
}

// ─── Buy hero card ────────────────────────────────────────────────────────────
function buildBuyHero(skin) {
  const wp      = skin.wearPrices || {};
  const vals    = Object.values(wp).filter(e => e?.priceEur > 0);
  const best    = vals.length ? vals.reduce((a,b) => a.priceEur<=b.priceEur ? a : b) : null;
  const priceStr= best?.priceStr || '—';
  const url     = best?.url || '#';
  const siteName= best?.url?.includes('white.market') ? 'white.market' : 'Market';
  const m       = { name: siteName, abbr: 'WM', bg: '#0b1a12', color: '#00d882', stars: 4.7 };

  return `
<div class="buy-hero">
  <div class="buy-eyebrow"><span class="live-dot"></span>Best price right now</div>
  <div class="buy-row">
    <div class="buy-price-col">
      <div class="buy-price" id="buyHeroPrice">${escH(priceStr)}</div>
      <div class="buy-orig" id="buyHeroSub">Cheapest available · <strong>${escH(siteName)}</strong></div>
    </div>
    <div class="buy-source" id="buyHeroSource">
      <div class="buy-source-logo" style="background:${m.bg};color:${m.color}">${m.abbr}</div>
      <div class="buy-source-info">
        <span class="buy-source-name">${escH(m.name)}</span>
        <span class="buy-source-rating">★★★★½ ${m.stars}</span>
      </div>
    </div>
  </div>
  <a class="buy-cta" id="buyHeroCta" href="${escA(url)}" target="_blank" rel="noopener">
    Buy on ${escH(siteName)}
    <svg width="13" height="13" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M3 8h10M9 4l4 4-4 4"/></svg>
  </a>
</div>`;
}

// ─── Info grid (2-col) ────────────────────────────────────────────────────────
function buildInfoGrid(skin) {
  const finish   = skin.finishName || skin.variant || '';
  const relDate  = fmtReleaseDate(skin.releaseDate);
  const rows = [
    { l: 'Category', v: 'Skin' },
    { l: 'Type',     v: CAT_LABELS[skin.category] || '—',   href: skin.category ? 'index.html?type='+encodeURIComponent(skin.category) : null },
    { l: 'Weapon',   v: skin.weaponName || skin.name,       href: (skin.weaponName||skin.name) ? 'index.html?weapon='+encodeURIComponent(skin.weaponName||skin.name)+'&type='+encodeURIComponent(skin.category||'') : null },
    { l: 'Finish',   v: finish,                              href: finish ? 'index.html?search='+encodeURIComponent(finish) : null },
    { l: 'Catalog',  v: skin.paintIndex ? '#'+skin.paintIndex : '—' },
    { l: 'Model',    v: skin.legacyModel ? 'Legacy / CS2' : 'CS2' },
    { l: 'Rarity',   v: RARITY_LABELS[skin.rarity] || '—', cls: 'rar-'+skin.rarity, href: skin.rarity ? 'index.html?rarity='+encodeURIComponent(skin.rarity) : null },
    { l: 'Team',     v: skin.team || '—' },
    { l: 'Collection', v: skin.collection || '—',           href: skin.collection ? 'index.html?collection='+encodeURIComponent(skin.collection) : null },
    { l: 'Released', v: relDate || '—' },
  ].filter(r => r.v && r.v !== '—');

  return `
<div class="card">
  <div class="card-hd"><div class="card-hd-title">Skin info</div></div>
  <div class="info-grid">
    ${rows.map(r => {
      const cls = 'info-v' + (r.cls ? ' '+r.cls : '');
      const val = r.href
        ? `<a class="${cls} info-link" href="${escA(r.href)}">${escH(r.v)}</a>`
        : `<span class="${cls}">${escH(r.v)}</span>`;
      return `<div class="info-row"><span class="info-l">${escH(r.l)}</span>${val}</div>`;
    }).join('')}
  </div>
</div>`;
}

function fmtReleaseDate(d) {
  if (!d) return null;
  const dt = new Date(d + 'T00:00:00Z');
  if (isNaN(dt.getTime())) return null;
  const day = dt.getUTCDate();
  const sfx = [11,12,13].includes(day) ? 'th' : day%10===1?'st':day%10===2?'nd':day%10===3?'rd':'th';
  return `${dt.toLocaleDateString('en-US',{month:'long',timeZone:'UTC'})} ${day}${sfx}, ${dt.getUTCFullYear()}`;
}

// ─── Comparator card ──────────────────────────────────────────────────────────
function buildComparatorPlaceholder() {
  return `
<div class="cmp" id="comparatorCard">
  <div class="cmp-hd">
    <div class="cmp-hd-l">
      <div class="cmp-hd-title"><span class="live-dot"></span>Price spread</div>
      <div class="cmp-hd-sub">loading markets…</div>
    </div>
    <div class="cmp-hd-right">
      <div class="cmp-style-btns">
        <button class="cmp-style-btn active" data-style="bars" onclick="setCmpStyle('bars')">Bars</button>
        <button class="cmp-style-btn" data-style="stack" onclick="setCmpStyle('stack')">Stack</button>
        <button class="cmp-style-btn" data-style="podium" onclick="setCmpStyle('podium')">Podium</button>
      </div>
      <div class="curr-toggle">
        <button class="active" onclick="setCmpCurrency('EUR')">€ EUR</button>
        <button onclick="setCmpCurrency('USD')">$ USD</button>
      </div>
    </div>
  </div>
  <div class="cmp-loading" id="cmpBody">
    <div class="cmp-spin"></div>
    <span style="font-size:12px;color:var(--muted)">Fetching prices…</span>
  </div>
</div>`;
}

// ─── Collection + Gallery (existing logic, new markup) ────────────────────────
function buildCollectionPlaceholder(skin) {
  if (!skin.collection && !(skin.skinCrates||[]).length) return '';
  return `
<div class="card" id="containersCard">
  <div class="card-hd"><div class="card-hd-title">Collection &amp; Containers</div></div>
  <div style="display:flex;gap:12px;overflow-x:auto;padding:14px 18px" id="containersInner">
    <span style="font-size:12px;color:var(--muted)">Loading…</span>
  </div>
</div>`;
}

function buildGallery(skin) {
  const imgs = [skin.image].filter(Boolean);
  return `
<div class="card">
  <div class="card-hd"><div class="card-hd-title">Gallery</div></div>
  <div class="gallery-grid">
    ${Array.from({length:4},(_,i) => {
      if (imgs[i]) return `<a class="gallery-slot" href="${escA(imgs[i])}" target="_blank" rel="noopener"><img src="${escA(imgs[i])}" alt="Gallery ${i+1}" loading="lazy"></a>`;
      return `<div class="gallery-slot gallery-ph"><span>More images<br>coming soon</span></div>`;
    }).join('')}
  </div>
</div>`;
}

// ─── Comparator state & rendering ────────────────────────────────────────────
window._cmpData     = null;  // array of market entries
window._cmpStyle    = 'bars';
window._cmpCurrency = 'EUR';

window.setCmpStyle = function(style) {
  window._cmpStyle = style;
  document.querySelectorAll('.cmp-style-btn').forEach(b => b.classList.toggle('active', b.dataset.style === style));
  if (window._cmpData) renderComparator(window._cmpData);
};

window.setCmpCurrency = function(c) {
  window._cmpCurrency = c;
  document.querySelectorAll('.curr-toggle button').forEach(b => b.classList.toggle('active', b.textContent.startsWith(c === 'EUR' ? '€' : '$')));
  if (window._cmpData) renderComparator(window._cmpData);
};

function renderComparator(markets) {
  const body = document.getElementById('cmpBody');
  if (!body) return;
  const sorted = [...markets].sort((a,b) => a.priceEur - b.priceEur);
  if (!sorted.length) { body.innerHTML = '<div class="cmp-err">Prix non disponible</div>'; return; }

  // update header sub
  const sub = document.querySelector('#comparatorCard .cmp-hd-sub');
  if (sub) sub.textContent = `${sorted.length} markets · updated just now`;

  const c = window._cmpCurrency;
  const p = m => c === 'USD' ? m.priceUsd : m.priceEur;
  const prices = sorted.map(p);
  const min = Math.min(...prices), max = Math.max(...prices);
  const span = Math.max(max - min, 0.01);
  const bestM = sorted[0];

  if (window._cmpStyle === 'bars') {
    const summaryHTML = `
<div class="cmp-summary">
  <div class="cmp-sum"><div class="cmp-sum-l">Cheapest</div><div class="cmp-sum-v green">${fmtPrice(min,c)}</div><div class="cmp-sum-s green">on ${escH(bestM.name)}</div></div>
  <div class="cmp-sum"><div class="cmp-sum-l">Spread</div><div class="cmp-sum-v">${((max-min)/min*100).toFixed(1)}%</div><div class="cmp-sum-s">range delta</div></div>
  <div class="cmp-sum"><div class="cmp-sum-l">You save</div><div class="cmp-sum-v">${fmtPrice(max-min,c)}</div><div class="cmp-sum-s">vs costliest</div></div>
</div>`;
    const barsHTML = sorted.map(m => {
      const mp = p(m);
      const fill = Math.max(38, 100 - ((mp-min)/span)*62);
      const isBest = m.source === bestM.source;
      const d = mp - min;
      return `
<a class="cmp-row${isBest?' best':''}" href="${escA(m.url||'#')}" target="_blank" rel="noopener">
  <div class="cmp-row-head">
    <div class="cmp-logo" style="background:${m.bg};color:${m.color}">${m.abbr}</div>
    <div class="cmp-name-wrap">
      <div class="cmp-name">${escH(m.name)}${isBest?'<span class="cmp-best-pill">Best</span>':''}</div>
      <div class="cmp-rating"><span style="color:#fbbf24">${'★'.repeat(Math.floor(m.stars))}${m.stars%1>=.5?'½':''}</span><span>${m.stars.toFixed(1)}</span></div>
    </div>
  </div>
  <div class="cmp-price-col">
    <div class="cmp-price">${fmtPrice(mp,c)}</div>
    <div class="cmp-delta">${deltaStr(d,c)}</div>
  </div>
  <div class="cmp-track"><div class="cmp-fill" style="width:${fill}%"></div></div>
  <div class="cmp-meta-row">
    <span>${((mp/min-1)*100).toFixed(1)}% vs best</span>
    <span>buy →</span>
  </div>
</a>`;
    }).join('');
    body.outerHTML = `<div id="cmpBody">${summaryHTML}<div class="cmp-bars">${barsHTML}</div><div class="cmp-foot"><span>Save <strong>${fmtPrice(max-min,c)}</strong> on <strong>${escH(bestM.name)}</strong></span><span style="font-family:'JetBrains Mono',monospace;font-size:10px;color:var(--muted2)">updated just now</span></div></div>`;

  } else if (window._cmpStyle === 'stack') {
    const rows = sorted.map((m,i) => {
      const mp = p(m); const d = mp - p(sorted[0]); const isBest = i===0;
      return `
<a class="cmp-stack-row${isBest?' best':''}" href="${escA(m.url||'#')}" target="_blank" rel="noopener">
  <div class="cmp-stack-logo" style="background:${m.bg};color:${m.color}">${m.abbr}</div>
  <div class="cmp-stack-info">
    <div class="cmp-stack-name-row"><span class="cmp-stack-name">${escH(m.name)}</span>${isBest?'<span class="cmp-best-pill">Best</span>':''}</div>
    <div class="cmp-stack-meta"><span style="color:#fbbf24">${'★'.repeat(Math.floor(m.stars))}</span><span class="cmp-stack-trust">${m.stars.toFixed(1)}</span></div>
  </div>
  <div class="cmp-stack-right">
    <div class="cmp-stack-price">${fmtPrice(mp,c)}</div>
    <div class="cmp-stack-delta">${isBest?'<span style="color:var(--green)">cheapest</span>':'+'+fmtPrice(d,c)}</div>
  </div>
</a>`;
    }).join('');
    body.outerHTML = `<div id="cmpBody"><div class="cmp-stack">${rows}</div></div>`;

  } else { // podium
    const top3 = sorted.slice(0,3), rest = sorted.slice(3);
    const podOrder = top3.length>=3 ? [top3[1],top3[0],top3[2]] : top3;
    const podCls   = top3.length>=3 ? ['silver','gold','bronze'] : ['gold','silver','bronze'];
    const podRank  = top3.length>=3 ? [2,1,3] : [1,2,3];
    const bestP = p(sorted[0]);
    const steps = podOrder.map((m,i) => {
      const mp = p(m); const d = mp - bestP;
      return `
<a class="cmp-step ${podCls[i]}" href="${escA(m.url||'#')}" target="_blank" rel="noopener">
  <div class="cmp-rank">${podRank[i]}</div>
  <div class="cmp-step-logo" style="background:${m.bg};color:${m.color}">${m.abbr}</div>
  <div class="cmp-step-name">${escH(m.name)}</div>
  <div class="cmp-step-price">${fmtPrice(mp,c)}</div>
  <div class="cmp-step-delta">${podCls[i]==='gold'?'<span style="color:var(--green)">cheapest</span>':'+'+fmtPrice(d,c)}</div>
</a>`;
    }).join('');
    const restRows = rest.map((m,idx) => {
      const mp = p(m); const d = mp - bestP;
      return `<a class="cmp-rest-row" href="${escA(m.url||'#')}" target="_blank" rel="noopener"><div class="cmp-rest-rank">${idx+4}</div><div class="cmp-rest-name">${escH(m.name)}</div><div class="cmp-rest-price">${fmtPrice(mp,c)}</div><div class="cmp-rest-delta">+${d.toFixed(2)}</div></a>`;
    }).join('');
    body.outerHTML = `<div id="cmpBody"><div class="cmp-podium"><div class="cmp-podium-grid">${steps}</div></div>${rest.length?'<div class="cmp-rest">'+restRows+'</div>':''}</div>`;
  }
}

async function initComparator(skin) {
  const wearFull = WN[skin.wear] || skin.wear || '';
  const mhn = (skin.name||'') + (skin.variant ? ' | '+skin.variant : '') + (wearFull ? ' ('+wearFull+')' : '');
  const API_BASE = (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')
    ? 'https://csskinsv2.vercel.app'
    : window.location.origin;
  const url = API_BASE + '/api/prices/all?market_hash_name=' + encodeURIComponent(mhn);

  try {
    const r    = await fetch(url);
    const data = await r.json();
    if (!data.prices?.length) {
      const body = document.getElementById('cmpBody');
      if (body) body.outerHTML = '<div id="cmpBody" class="cmp-err">Prix non disponible pour ce skin.</div>';
      return;
    }
    const markets = data.prices.map(p => {
      const m    = MP_SOURCE_META[p.source] || { name: p.source, abbr: p.source.slice(0,2).toUpperCase(), bg: '#1a1f2a', color: '#7b8698', stars: 4.0 };
      const priceEur = p.currency === 'EUR' ? p.price : p.price * USD_TO_EUR;
      const priceUsd = p.currency === 'USD' ? p.price : p.price / USD_TO_EUR;
      return { source: p.source, name: m.name, abbr: m.abbr, bg: m.bg, color: m.color, stars: m.stars, priceEur, priceUsd, url: p.url || '#' };
    });
    window._cmpData = markets;
    renderComparator(markets);

    // also update buy-hero with best market price from comparator
    const sorted = [...markets].sort((a,b) => a.priceEur - b.priceEur);
    const best   = sorted[0];
    if (best) updateBuyHero(best);
  } catch(e) {
    console.error('[comparator]', e);
    const body = document.getElementById('cmpBody');
    if (body) body.outerHTML = `<div id="cmpBody" class="cmp-err">Erreur : <code>${escH(e.message)}</code></div>`;
  }
}

function updateBuyHero(best) {
  const priceEl  = document.getElementById('buyHeroPrice');
  const subEl    = document.getElementById('buyHeroSub');
  const ctaEl    = document.getElementById('buyHeroCta');
  const srcEl    = document.getElementById('buyHeroSource');
  if (priceEl) priceEl.textContent = '€' + best.priceEur.toFixed(2);
  if (subEl)   subEl.innerHTML = `Cheapest available · <strong>${escH(best.name)}</strong>`;
  if (ctaEl)   { ctaEl.href = best.url; ctaEl.innerHTML = `Buy on ${escH(best.name)} <svg width="13" height="13" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M3 8h10M9 4l4 4-4 4"/></svg>`; }
  if (srcEl)   srcEl.innerHTML = `<div class="buy-source-logo" style="background:${best.bg};color:${best.color}">${best.abbr}</div><div class="buy-source-info"><span class="buy-source-name">${escH(best.name)}</span><span class="buy-source-rating">★★★★½ ${best.stars}</span></div>`;
}

// ─── Main render ─────────────────────────────────────────────────────────────
function render(skin) {
  if (window._viewer) { window._viewer.dispose(); window._viewer = null; }
  window._is3d = false;
  window._skin = skin;
  window._currentVariant = 'normal';

  const catLabel = CAT_LABELS[skin.category] || 'Skins';
  document.title  = skin.name + (skin.variant ? ' | '+skin.variant : '') + ' — CSSkins';
  document.getElementById('bcCat').textContent  = catLabel;
  document.getElementById('bcName').textContent = skin.name + (skin.variant ? ' | '+skin.variant : '');

  document.getElementById('root').innerHTML =
    buildHero(skin) +
    `<div class="page">
      <div class="left">
        ${buildViewerCard(skin)}
        ${buildFloatCard(skin)}
        ${buildWearGrid(skin)}
        ${buildCollectionPlaceholder(skin)}
        ${buildGallery(skin)}
      </div>
      <div class="right">
        ${buildBuyHero(skin)}
        ${buildComparatorPlaceholder()}
        ${buildInfoGrid(skin)}
      </div>
    </div>`;

  initFloatSlider(skin);
  initComparator(skin);
  initContainers(skin);
}

// ─── Variant switch (wear grid) ───────────────────────────────────────────────
window.setVariant = function(v) {
  window._currentVariant = v;
  document.querySelectorAll('.variant-tab').forEach(b => b.classList.toggle('active', b.dataset.variant === v));
  const body = document.getElementById('wearGridBody');
  if (body) body.innerHTML = buildWearCells(window._skin, v);
};

// ─── Float slider ─────────────────────────────────────────────────────────────
const FLOAT_ZONES = [
  { wear:'FN', min:0, max:0.07 }, { wear:'MW', min:0.07, max:0.15 },
  { wear:'FT', min:0.15, max:0.38 }, { wear:'WW', min:0.38, max:0.45 },
  { wear:'BS', min:0.45, max:1.00 },
];
const ZONE_COLORS = { FN:'#00d882', MW:'#7dc84e', FT:'#ffe760', WW:'#f09832', BS:'#eb4b4b' };
const GRAY_ZONE   = '#2a3040';

function buildTrackGradient(minF, maxF) {
  const stops = [];
  if (minF > 0.001) stops.push(`${GRAY_ZONE} 0%`, `${GRAY_ZONE} ${(minF*100).toFixed(2)}%`);
  for (const z of FLOAT_ZONES) {
    const s = Math.max(z.min, minF), e = Math.min(z.max, maxF);
    if (e <= s) continue;
    stops.push(`${ZONE_COLORS[z.wear]} ${(s*100).toFixed(2)}%`, `${ZONE_COLORS[z.wear]} ${(e*100).toFixed(2)}%`);
  }
  if (maxF < 0.999) stops.push(`${GRAY_ZONE} ${(maxF*100).toFixed(2)}%`, `${GRAY_ZONE} 100%`);
  return stops.length ? `linear-gradient(90deg, ${stops.join(', ')})` : '';
}

function initFloatSlider(skin) {
  const slider = document.getElementById('floatSlider');
  const track  = document.getElementById('floatTrack');
  if (!slider || !track) return;
  const minF = skin.minFloat ?? 0.00, maxF = skin.maxFloat ?? 1.00;
  track.style.background = buildTrackGradient(minF, maxF);
  slider.addEventListener('input', () => {
    let val = parseFloat(slider.value);
    if (val < minF) { val = minF; slider.value = String(minF); }
    if (val > maxF) { val = maxF; slider.value = String(maxF); }
    onFloatChange(val);
  });
  onFloatChange(parseFloat(slider.value));
}

function onFloatChange(floatVal) {
  const wear     = floatToWear(floatVal);
  const wearFull = WN[wear] || wear;
  const numEl  = document.getElementById('floatNum');
  const nameEl = document.getElementById('floatWearName');
  const pillEl = document.getElementById('floatWearPill');
  const dispEl = document.getElementById('floatDisplay');
  const wearEl = document.getElementById('floatWearTxt');
  if (numEl)  numEl.textContent  = floatVal.toFixed(4);
  if (nameEl) nameEl.textContent = wearFull;
  if (pillEl) { pillEl.textContent = wear; pillEl.className = 'float-wear-pill w-'+wear; }
  if (dispEl) dispEl.textContent = floatVal.toFixed(4);
  if (wearEl) wearEl.textContent = wearFull;
  if (window._viewer) window._viewer.setFloat(floatVal);
}

// ─── Collection loading ───────────────────────────────────────────────────────
async function initContainers(skin) {
  const wrap = document.getElementById('containersInner');
  if (!wrap) return;
  if (!window._cratesDB) {
    try {
      const r = await fetch('https://raw.githubusercontent.com/bymykel/CSGO-API/master/api/en/crates.json');
      window._cratesDB = r.ok ? await r.json() : [];
    } catch(_) { window._cratesDB = []; }
  }
  const db = window._cratesDB;
  const norm = s => (s||'').toLowerCase().trim();
  function resolveItem(name, kind, fallbackImg) {
    const match = db.find(e => norm(e.name) === norm(name));
    return { kind, name, image: match?.image || fallbackImg || '', url: 'https://steamcommunity.com/market/listings/730/'+encodeURIComponent(name) };
  }
  const items = [];
  if (skin.collection) items.push(resolveItem(skin.collection, 'Collection', skin.collectionImg));
  for (const c of (skin.skinCrates||[])) if (c.name) items.push(resolveItem(c.name, 'Container', c.image));
  if (!items.length) { wrap.innerHTML = '<span style="font-size:12px;color:var(--muted2)">No data available</span>'; return; }
  wrap.innerHTML = items.map(item => `
<a style="flex-shrink:0;width:130px;background:var(--surface2);border:1px solid var(--border);border-radius:var(--rs);padding:11px 10px;text-align:center;display:flex;flex-direction:column;align-items:center;gap:7px;text-decoration:none;color:inherit;transition:border-color .12s" href="${escA(item.url)}" target="_blank" rel="noopener">
  ${item.image ? `<img style="width:88px;height:66px;object-fit:contain;opacity:.9" src="${escA(item.image)}" alt="${escA(item.name)}" loading="lazy" onerror="this.style.opacity='.15'">` : `<div style="width:88px;height:66px;background:var(--surface3);border-radius:5px;border:1px dashed var(--border2)"></div>`}
  <div style="font-size:9px;font-weight:700;letter-spacing:.6px;text-transform:uppercase;color:var(--muted2)">${escH(item.kind)}</div>
  <div style="font-size:11px;font-weight:600;color:var(--muted);line-height:1.3">${escH(item.name)}</div>
</a>`).join('');
}

function showNotFound() {
  document.getElementById('root').innerHTML = `
<div style="display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:60vh;gap:16px;padding:40px">
  <h2 style="font-family:'Barlow Condensed',sans-serif;font-size:32px;font-weight:900">Skin not found</h2>
  <p style="color:var(--muted)">This skin couldn't be loaded.</p>
  <a style="color:var(--accent);font-size:13px;font-weight:600" href="index.html">← Back to all skins</a>
</div>`;
}
