// Responsibility: build all HTML for the skin detail page

const W_BADGE_CLS = { FN:'w-fn', MW:'w-mw', FT:'w-ft', WW:'w-ww', BS:'w-bs' };

const MP_META = {
  'white.market': { logo:'WM', logoBg:'#0b1a12', logoColor:'#00d882', stars: 4.7, reviews:'2.1k', partner: true  },
  'CSFloat':      { logo:'CF', logoBg:'#0d1520', logoColor:'#5b8af5', stars: 4.6, reviews:'5.2k', partner: false },
  'DMarket':      { logo:'DM', logoBg:'#0c1624', logoColor:'#4a9eff', stars: 4.5, reviews:'8.3k', partner: false },
};

const INFO_ICONS = {
  tag:     `<svg class="info-icon" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M2 2h5.5l6 6-5.5 5.5-6-6V2z"/><circle cx="5" cy="5" r=".9" fill="currentColor" stroke="none"/></svg>`,
  target:  `<svg class="info-icon" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"><circle cx="8" cy="8" r="5.5"/><line x1="8" y1="1" x2="8" y2="4"/><line x1="8" y1="12" x2="8" y2="15"/><line x1="1" y1="8" x2="4" y2="8"/><line x1="12" y1="8" x2="15" y2="8"/></svg>`,
  gun:     `<svg class="info-icon" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M1 7h9v2.5H7.5L7 12H5l-.5-2.5H1V7z"/><rect x="9.5" y="6" width="5" height="2.5" rx=".6"/></svg>`,
  palette: `<svg class="info-icon" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"><path d="M8 1a7 7 0 0 0 0 14c.7 0 1-.4 1-1v-1.5c0-.5.5-1 1-1H12a3 3 0 0 0 0-6A7 7 0 0 0 8 1z"/><circle cx="5.5" cy="6" r=".7" fill="currentColor" stroke="none"/><circle cx="8" cy="4" r=".7" fill="currentColor" stroke="none"/><circle cx="10.5" cy="6" r=".7" fill="currentColor" stroke="none"/></svg>`,
  hash:    `<svg class="info-icon" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"><line x1="5.5" y1="2" x2="4.5" y2="14"/><line x1="11.5" y1="2" x2="10.5" y2="14"/><line x1="2" y1="6" x2="14" y2="6"/><line x1="2" y1="10" x2="14" y2="10"/></svg>`,
  shuffle: `<svg class="info-icon" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M1 4h3l7 8h3"/><path d="M14 4h-3L6 8.5"/><polyline points="12,2 14,4 12,6"/><polyline points="12,10 14,12 12,14"/></svg>`,
  monitor: `<svg class="info-icon" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><rect x="1" y="2" width="14" height="9.5" rx="1.5"/><line x1="5" y1="15" x2="11" y2="15"/><line x1="8" y1="11.5" x2="8" y2="15"/></svg>`,
  star:    `<svg class="info-icon" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><polygon points="8,2 10,6.5 15,6.5 11,9.5 12.5,14.5 8,11.5 3.5,14.5 5,9.5 1,6.5 6,6.5"/></svg>`,
  users:   `<svg class="info-icon" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="6" cy="5.5" r="2.5"/><path d="M1 14c0-2.8 2.2-4.5 5-4.5s5 1.7 5 4.5"/><circle cx="12" cy="5.5" r="2" opacity=".5"/><path d="M14 13.5c0-2-1.3-3.5-3-4" opacity=".5"/></svg>`,
  box:      `<svg class="info-icon" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="13.5,5 8,7.5 2.5,5"/><path d="M2.5 5L8 2.5l5.5 2.5v6L8 13.5 2.5 11V5z"/><line x1="8" y1="7.5" x2="8" y2="13.5"/></svg>`,
  calendar: `<svg class="info-icon" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><rect x="1.5" y="3" width="13" height="11.5" rx="1.5"/><line x1="1.5" y1="7" x2="14.5" y2="7"/><line x1="5" y1="1.5" x2="5" y2="4.5"/><line x1="11" y1="1.5" x2="11" y2="4.5"/></svg>`,
};

const PATTERN_VAR_RE = /doppler|case hardened|marble fade|tiger tooth|lore|gamma|vanilla|ruby|sapphire|black pearl|emerald|crimson web|damascus|rust coat/i;

function render(skin) {
  if (window._viewer) { window._viewer.dispose(); window._viewer = null; }
  window._is3d = false;
  window._skin = skin;
  window._currentCategory = 'normal';

  const catLabel = CAT_LABELS[skin.category] || 'Skins';
  const rarLabel = RARITY_LABELS[skin.rarity] || 'Common';
  const wearFull = WN[skin.wear] || skin.wear || '';
  const floatNum = parseFloat(skin.float) || WF[skin.wear] || 0.15;
  const floatStr = skin.float || floatNum.toFixed(4);
  const minFloat = skin.minFloat ?? 0.00;
  const maxFloat = skin.maxFloat ?? 1.00;

  const hasST = skin.stattrak === true || WO.some(w => (skin.stWearPrices||{})[w]);
  const hasSV = skin.souvenir === true || WO.some(w => (skin.svWearPrices||{})[w]);

  document.title = skin.name + (skin.variant ? ' | ' + skin.variant : '') + ' — CSSkins';
  document.getElementById('bcCat').textContent  = catLabel;
  document.getElementById('bcName').textContent = skin.name + (skin.variant ? ' | ' + skin.variant : '');

  const wp      = skin.wearPrices || {};
  const wpVals  = Object.values(wp).filter(e => e && e.priceEur > 0);
  const bestEntry = wpVals.length
    ? wpVals.reduce((a,b) => a.priceEur<=b.priceEur ? a : b)
    : skin.prices?.[0] || null;
  const bestStr  = bestEntry?.priceStr || bestEntry?.price || '—';
  const bestSite = bestEntry?.url?.includes('white.market') ? 'white.market' : (skin.prices?.[0]?.site || 'Market');

  const catSwitchHtml = (hasST || hasSV) ? `
  <div class="cat-switch" id="catSwitch">
    <button class="cat-btn active" data-cat="normal" onclick="setCategory('normal')">Normal</button>
    ${hasST ? '<button class="cat-btn st" data-cat="st" onclick="setCategory(\'st\')">StatTrak™</button>' : ''}
    ${hasSV ? '<button class="cat-btn sv" data-cat="sv" onclick="setCategory(\'sv\')">Souvenir</button>' : ''}
  </div>` : '';

  document.getElementById('root').innerHTML = `
<div class="skin-header">
  <div class="skin-header-inner">
    <div class="skin-cat-label">${escH(catLabel)}</div>
    <h1 class="skin-h1">${escH(skin.name)}${skin.variant ? ' | <span class="variant">' + escH(skin.variant) + '</span>' : ''}</h1>
    <div class="skin-meta">
      <span class="badge-rarity r-${skin.rarity}">${rarLabel}</span>
      <span class="chip">${escH(wearFull)}</span>
      ${skin.collection ? '<span class="chip">' + escH(skin.collection) + '</span>' : ''}
    </div>
  </div>
</div>

<div class="page">
  <div class="left">
    <div class="img-card">
      <div class="view-tabs" id="viewTabs">
        <button class="view-tab active" data-tab="wear" onclick="setViewTab('wear')">Wear</button>
        <button class="view-tab" data-tab="3d" onclick="setViewTab('3d')">3D View</button>
      </div>
      <div class="img-stage">
        <img id="skinImg" src="${escA(skin.image)}"
             alt="${escA((skin.name||'') + (skin.variant ? ' | '+skin.variant : ''))}"
             onerror="this.style.opacity='.08'"
             onclick="toggleZoom()" />
        <div id="viewer3d" class="viewer3d">
          <div class="vd-drop" id="viewerDrop">
            <div class="vd-icon">⬡</div>
            <div class="vd-title">CS2 3D Viewer</div>
            <div class="vd-hint">Drop a <strong>.glb</strong> weapon model here</div>
            <div class="vd-sub">Also drop textures: albedo · wear_mask</div>
          </div>
          <canvas id="viewer3dCanvas" style="display:none"></canvas>
        </div>
        <div id="inspectFrame" class="inspect-frame"></div>
        <div class="img-btns" id="imgBtns">
          <button class="img-btn" onclick="toggleMirror()">↺ Flip</button>
          <button class="img-btn" id="btn3d" onclick="toggle3DView()">⬡ 3D</button>
          <button class="img-btn" onclick="copyURL()">🔗 Share</button>
        </div>
      </div>
      <div class="viewer-controls" id="viewerControls" style="display:none">
        <div class="vc-left">
          <span class="vc-label">Pattern <span id="seedVal">1</span></span>
          <input type="range" id="seedSlider" class="vc-range" min="1" max="1000" step="1" value="1">
        </div>
        <div class="vc-finish">
          <button class="vf-btn active" data-finish="0" onclick="setViewerFinish(0)">Custom Paint</button>
          <button class="vf-btn" data-finish="1" onclick="setViewerFinish(1)">Patina</button>
          <button class="vf-btn" data-finish="2" onclick="setViewerFinish(2)">Gunsmith</button>
        </div>
      </div>
      <div class="img-bar">
        <div class="float-label">Float: <strong>${escH(floatStr)}</strong> · ${escH(wearFull)}</div>
        <div class="float-pill">white.market · Live</div>
      </div>
    </div>

    <div class="float-section">
      <div class="float-sec-title">Float Value</div>
      <div class="float-row">
        <div class="float-num" id="floatDisplay">${escH(floatStr)}</div>
        <div class="float-wear-txt" id="floatWearTxt">${escH(wearFull)}</div>
      </div>
      <div class="float-track-wrap">
        <div class="float-track" id="floatTrack"></div>
        <input type="range" id="floatSlider" class="float-range"
               min="0" max="1" step="0.0001" value="${floatNum}" />
      </div>
      <div class="float-ticks">
        <span>FN</span><span>MW</span><span>FT</span><span>WW</span><span>BS</span>
      </div>
      <div class="float-price-row" id="floatPriceRow"></div>
    </div>

    <div class="prices-card">
      <div class="prices-head">
        <div class="prices-head-title">Prices by wear</div>
        <div class="prices-head-src">
          <div class="live-dot"></div>
          white.market · Live
        </div>
      </div>
      ${buildWearRows(skin)}
    </div>
  </div>

  <div class="right">
    ${catSwitchHtml}
    <div class="best-card">
      <div class="best-eyebrow"><div class="live-dot"></div> Best price right now</div>
      <div class="best-price-big">${escH(bestStr)}</div>
      <div class="best-sub">Cheapest available · <strong>${escH(bestSite)}</strong></div>
      <a class="best-buy-btn" href="${bestEntry?.url ? escA(bestEntry.url) : '#'}" target="_blank" rel="noopener">
        Buy on ${escH(bestSite)} →
      </a>
    </div>

    <div class="offers-card">
      <div class="offers-head">
        <div class="offers-title">Active Offers</div>
        <div class="offers-cnt" id="offersCnt"></div>
      </div>
      <div id="offersBody">${buildOffersForWear(skin, 'normal', floatToWear(floatNum))}</div>
    </div>

    <div class="info-card">
      <div class="info-head">
        <div class="info-head-title">Skin Info</div>
      </div>
      ${buildSkinInfo(skin)}
    </div>
  </div>
</div>

<div class="extra-sections">
  <div class="extra-card" id="colorsCard">
    <div class="extra-head">Colors</div>
    <div class="colors-swatches" id="colorsSwatches">
      <span class="swatch-loading">Extracting colors…</span>
    </div>
  </div>
  ${buildContainers(skin)}
  ${buildGallery(skin)}
</div>`;

  const n  = document.querySelectorAll('.offer-row:not(.oos)').length;
  const el = document.getElementById('offersCnt');
  if (el) el.textContent = n + ' marketplace' + (n !== 1 ? 's' : '');

  initFloatSlider(skin);
  initColors(skin);
  initContainers(skin);
}

function buildWearRows(skin) {
  const wp = skin.wearPrices   || {};
  const sp = skin.stWearPrices || {};
  const sv = skin.svWearPrices || {};

  const hasNormal = WO.some(w => wp[w]);
  const hasST     = WO.some(w => sp[w]);
  const hasSV     = WO.some(w => sv[w]);

  if (!hasNormal && !hasST && !hasSV) {
    return (skin.prices || []).map(p => `
      <a class="w-row best" href="${escA(p.url)}" target="_blank" rel="noopener">
        <div class="w-badge w-ft">—</div>
        <div class="w-name">${escH(p.site||'Market')}</div>
        <div class="w-price">${escH(p.price||'—')}</div>
        <div class="w-buy">Buy →</div>
      </a>`).join('');
  }

  let html = '';

  if (hasNormal) {
    const have = WO.filter(w => wp[w]);
    const best = have.reduce((a,b) => wp[a].priceEur <= wp[b].priceEur ? a : b);
    html += WO.map(w => {
      const p = wp[w];
      const isBest = w === best;
      if (!p) return `
        <div class="w-row unavail">
          <div class="w-badge ${W_BADGE_CLS[w]}">${w}</div>
          <div class="w-name">${WN[w]}</div>
          <div class="w-na">—</div>
        </div>`;
      return `
      <a class="w-row${isBest?' best':''}" href="${escA(p.url)}" target="_blank" rel="noopener">
        <div class="w-badge ${W_BADGE_CLS[w]}">${w}</div>
        <div class="w-name">${WN[w]}</div>
        <div class="w-price">${escH(p.priceStr)}</div>
        ${isBest ? '<span class="w-best-tag normal">BEST</span>' : ''}
        <div class="w-buy">Buy →</div>
      </a>`;
    }).join('');
  }

  if (hasST) {
    const have = WO.filter(w => sp[w]);
    const best = have.length ? have.reduce((a,b) => sp[a].priceEur <= sp[b].priceEur ? a : b) : null;
    html += `<div class="w-divider st">StatTrak™</div>`;
    html += WO.map(w => {
      const p = sp[w];
      const isBest = w === best;
      if (!p) return `
        <div class="w-row unavail">
          <div class="w-badge ${W_BADGE_CLS[w]}">${w}</div>
          <div class="w-name">StatTrak™ ${WN[w]}</div>
          <div class="w-na">—</div>
        </div>`;
      return `
      <a class="w-row st-row${isBest?' best':''}" href="${escA(p.url)}" target="_blank" rel="noopener">
        <div class="w-badge ${W_BADGE_CLS[w]}">${w}</div>
        <div class="w-name">StatTrak™ ${WN[w]}</div>
        <div class="w-price">${escH(p.priceStr)}</div>
        ${isBest ? '<span class="w-best-tag st">BEST</span>' : ''}
        <div class="w-buy">Buy →</div>
      </a>`;
    }).join('');
  }

  if (hasSV) {
    const have = WO.filter(w => sv[w]);
    const best = have.length ? have.reduce((a,b) => sv[a].priceEur <= sv[b].priceEur ? a : b) : null;
    html += `<div class="w-divider sv">Souvenir</div>`;
    html += WO.map(w => {
      const p = sv[w];
      const isBest = w === best;
      if (!p) return `
        <div class="w-row unavail">
          <div class="w-badge ${W_BADGE_CLS[w]}">${w}</div>
          <div class="w-name">Souvenir ${WN[w]}</div>
          <div class="w-na">—</div>
        </div>`;
      return `
      <a class="w-row sv-row${isBest?' best':''}" href="${escA(p.url)}" target="_blank" rel="noopener">
        <div class="w-badge ${W_BADGE_CLS[w]}">${w}</div>
        <div class="w-name">Souvenir ${WN[w]}</div>
        <div class="w-price">${escH(p.priceStr)}</div>
        ${isBest ? '<span class="w-best-tag sv">BEST</span>' : ''}
        <div class="w-buy">Buy →</div>
      </a>`;
    }).join('');
  }

  return html;
}

function buildOffersForWear(skin, cat, wear) {
  const wearMap = cat === 'st' ? (skin.stWearPrices || {})
                : cat === 'sv' ? (skin.svWearPrices || {})
                : (skin.wearPrices || {});

  const sources = [];

  // white.market — per-wear, per-variant
  const wmEntry = wearMap[wear];
  sources.push({
    name: 'white.market',
    inStock:  !!(wmEntry && wmEntry.priceEur > 0),
    priceEur: wmEntry?.priceEur || 0,
    priceStr: wmEntry?.priceStr || null,
    url:      wmEntry?.url      || null,
    count:    wmEntry ? 1 : 0,
  });

  // CSFloat — single listing; wear-matched via stored wearName or skin.wear
  if (skin.csfloatUrl) {
    const cfP    = (skin.prices || []).find(p => p.site === 'CSFloat');
    const cfWear = cfP?.wearName ? (WEAR_FULL[cfP.wearName] || skin.wear) : skin.wear;
    const ok     = cfWear === wear;
    sources.push({
      name: 'CSFloat',
      inStock:  ok,
      priceEur: ok ? (cfP?.priceNum || 0) : 0,
      priceStr: ok ? (cfP?.price    || null) : null,
      url:      ok ? skin.csfloatUrl : null,
      count:    ok ? 1 : 0,
    });
  }

  // DMarket — single listing, normal category only, wear-matched via skin.wear
  if (cat === 'normal' && skin.dmarketUrl) {
    const dmP = (skin.prices || []).find(p => p.site === 'DMarket');
    const ok  = dmP && skin.wear === wear;
    sources.push({
      name: 'DMarket',
      inStock:  !!ok,
      priceEur: ok ? (dmP.priceNum || 0) : 0,
      priceStr: ok ? (dmP.price    || null) : null,
      url:      ok ? skin.dmarketUrl : null,
      count:    ok ? 1 : 0,
    });
  }

  if (!sources.length) {
    return '<div style="padding:18px;color:var(--muted);font-size:13px">No marketplace data available.</div>';
  }

  // CHEAPEST badge: only when 2+ sources are in stock
  const inStock      = sources.filter(s => s.inStock);
  const cheapestName = inStock.length >= 2
    ? inStock.reduce((a, b) => a.priceEur < b.priceEur ? a : b).name
    : null;

  return sources.map(src => {
    const m = MP_META[src.name] || {
      logo: src.name.slice(0,2).toUpperCase(), logoBg:'#1a1f2a',
      logoColor:'#7b8698', stars: 4.0, reviews:'?', partner: false,
    };
    const stars = '★'.repeat(Math.floor(m.stars)) + (m.stars%1>=.5?'½':'') + '☆'.repeat(5-Math.ceil(m.stars));

    if (!src.inStock) {
      return `
    <div class="offer-row oos">
      <div class="offer-logo" style="background:${m.logoBg};color:${m.logoColor};opacity:.4">${m.logo}</div>
      <div class="offer-info">
        <div class="offer-name-row">
          <span class="offer-name">${escH(src.name)}</span>
          ${m.partner ? '<span class="partner-badge" style="opacity:.5">PARTNER</span>' : ''}
        </div>
        <div class="offer-meta-row">
          <span class="offer-stars" style="opacity:.35">${stars}</span>
          <span class="offer-trust" style="opacity:.35">${m.stars.toFixed(1)}</span>
        </div>
      </div>
      <div class="offer-right">
        <div class="offer-oos-label">Out of Stock</div>
      </div>
    </div>`;
    }

    const isCheapest = src.name === cheapestName;
    return `
    <div class="offer-row${m.partner?' partner':''}">
      <div class="offer-logo" style="background:${m.logoBg};color:${m.logoColor}">${m.logo}</div>
      <div class="offer-info">
        <div class="offer-name-row">
          <span class="offer-name">${escH(src.name)}</span>
          ${m.partner ? '<span class="partner-badge">PARTNER</span>' : ''}
          ${isCheapest ? '<span class="cheapest-badge">CHEAPEST</span>' : ''}
        </div>
        <div class="offer-meta-row">
          <span class="offer-stars">${stars}</span>
          <span class="offer-trust">${m.stars.toFixed(1)}</span>
          <span class="offer-listings">· ${src.count} offer${src.count!==1?'s':''}</span>
        </div>
      </div>
      <div class="offer-right">
        <div class="offer-from-label">from</div>
        <div class="offer-price">${escH(src.priceStr)}</div>
        <a class="offer-btn" href="${escA(src.url)}" target="_blank" rel="noopener">View Offer →</a>
      </div>
    </div>`;
  }).join('');
}

function fmtReleaseDate(d) {
  if (!d) return null;
  const dt = new Date(d + 'T00:00:00Z');
  if (isNaN(dt.getTime())) return null;
  const day = dt.getUTCDate();
  const sfx = [11,12,13].includes(day) ? 'th'
    : day % 10 === 1 ? 'st'
    : day % 10 === 2 ? 'nd'
    : day % 10 === 3 ? 'rd' : 'th';
  const month = dt.toLocaleDateString('en-US', { month: 'long', timeZone: 'UTC' });
  return `${month} ${day}${sfx}, ${dt.getUTCFullYear()}`;
}

function buildSkinInfo(skin) {
  const finish     = skin.finishName || skin.variant || '';
  const rarityCode = skin.rarity || '';
  const rarityName = skin.rarityName || RARITY_LABELS[rarityCode] || '';
  const collection = skin.collection || '';
  const relDate    = fmtReleaseDate(skin.releaseDate);

  const rows = [
    { icon:'tag',      label:'Category',         val: 'Skin' },
    { icon:'target',   label:'Type',   val: CAT_LABELS[skin.category] || '—',
      href: skin.category ? 'index.html?type=' + encodeURIComponent(skin.category) : null },
    { icon:'gun',      label:'Weapon', val: skin.weaponName || skin.name,
      href: (skin.weaponName || skin.name)
        ? 'index.html?weapon=' + encodeURIComponent(skin.weaponName || skin.name) + '&type=' + encodeURIComponent(skin.category || '')
        : null },
    { icon:'palette',  label:'Finish',           val: finish,
      href: finish ? 'index.html?search=' + encodeURIComponent(finish) : null },
    { icon:'hash',     label:'Finish Catalog',   val: skin.paintIndex || '—' },
    { icon:'shuffle',  label:'Pattern Variants', val: PATTERN_VAR_RE.test(finish) ? 'Yes' : 'No' },
    { icon:'monitor',  label:'Model Version',    val: skin.legacyModel ? 'Legacy / CS2' : 'CS2' },
    { icon:'star',     label:'Rarity',           val: rarityName, cls: 'rc-' + rarityCode,
      href: rarityCode ? 'index.html?rarity=' + encodeURIComponent(rarityCode) : null },
    { icon:'users',    label:'Team',             val: skin.team || '—' },
    { icon:'box',      label:'Collection',       val: collection,
      href: collection ? 'index.html?collection=' + encodeURIComponent(collection) : null },
    { icon:'calendar', label:'Released',         val: relDate,
      href: collection ? 'index.html?collection=' + encodeURIComponent(collection) : null },
  ];

  return `<div class="info-list">${
    rows.filter(r => r.val && r.val !== '—').map(r => {
      const cls   = r.cls ? ' ' + escH(r.cls) : '';
      const inner = escH(r.val);
      const val   = r.href
        ? `<a class="info-value info-link${cls}" href="${escA(r.href)}">${inner}</a>`
        : `<span class="info-value${cls}">${inner}</span>`;
      return `
    <div class="info-row">
      <div class="info-row-left">
        ${INFO_ICONS[r.icon] || ''}
        <span class="info-label">${escH(r.label)}</span>
      </div>
      ${val}
    </div>`;
    }).join('')
  }</div>`;
}

// ─── Extra sections ───────────────────────────────────────────────────────────

function buildContainers(skin) {
  if (!skin.collection && !(skin.skinCrates || []).length) return '';
  return `
<div class="extra-card" id="containersCard">
  <div class="extra-head">Collection &amp; Containers</div>
  <div class="containers-scroll" id="containersInner">
    <span class="swatch-loading">Loading…</span>
  </div>
</div>`;
}

async function initContainers(skin) {
  const wrap = document.getElementById('containersInner');
  if (!wrap) return;

  // Fetch & cache crates DB
  if (!window._cratesDB) {
    try {
      const r = await fetch('https://raw.githubusercontent.com/bymykel/CSGO-API/master/api/en/crates.json');
      window._cratesDB = r.ok ? await r.json() : [];
    } catch(_) { window._cratesDB = []; }
  }

  const db = window._cratesDB;
  const norm = s => (s || '').toLowerCase().trim();

  // Helper: find best image + Steam Market link by name
  function resolveItem(name, kind, fallbackImg) {
    const match = db.find(e => norm(e.name) === norm(name));
    return {
      kind,
      name,
      image: match?.image || fallbackImg || '',
      url: 'https://steamcommunity.com/market/listings/730/' + encodeURIComponent(name),
    };
  }

  const items = [];
  if (skin.collection) {
    items.push(resolveItem(skin.collection, 'Collection', skin.collectionImg));
  }
  for (const c of (skin.skinCrates || [])) {
    if (c.name) items.push(resolveItem(c.name, 'Container', c.image));
  }

  if (!items.length) {
    wrap.innerHTML = '<span class="swatch-na">No data available</span>';
    return;
  }

  wrap.innerHTML = items.map(item => `
  <a class="container-card" href="${escA(item.url)}" target="_blank" rel="noopener">
    ${item.image
      ? `<img class="container-img" src="${escA(item.image)}" alt="${escA(item.name)}" loading="lazy" onerror="this.style.opacity='.15'">`
      : `<div class="container-img-ph"></div>`}
    <div class="container-kind">${escH(item.kind)}</div>
    <div class="container-name">${escH(item.name)}</div>
  </a>`).join('');
}

function buildGallery(skin) {
  const imgs = [skin.image].filter(Boolean);
  return `
<div class="extra-card">
  <div class="extra-head">Gallery</div>
  <div class="gallery-grid">
    ${Array.from({ length: 4 }, (_, i) => {
      if (imgs[i]) return `
    <a class="gallery-slot" href="${escA(imgs[i])}" target="_blank" rel="noopener">
      <img src="${escA(imgs[i])}" alt="Gallery ${i + 1}" loading="lazy">
    </a>`;
      return `<div class="gallery-slot gallery-ph"><span>More images<br>coming soon</span></div>`;
    }).join('')}
  </div>
</div>`;
}

function initColors(skin) {
  const el = document.getElementById('colorsSwatches');
  if (!el) return;

  function loadAndExtract(src, onCorsFail) {
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.onload = () => {
      let colors;
      try {
        colors = extractPalette(img);      // throws SecurityError on tainted canvas
      } catch(e) {
        if (e.name === 'SecurityError' && onCorsFail) { onCorsFail(); return; }
        renderFallbackPalette(el, skin); return;
      }
      if (colors) renderSwatches(el, colors);
      else renderFallbackPalette(el, skin);
    };
    img.onerror = () => {
      if (onCorsFail) onCorsFail(); else renderFallbackPalette(el, skin);
    };
    img.src = src;
  }

  const proxy = 'https://images.weserv.nl/?url=' + encodeURIComponent(skin.image);
  loadAndExtract(skin.image, () => loadAndExtract(proxy, null));
}

function extractPalette(img) {
  const SZ = 80;
  const cv  = document.createElement('canvas');
  cv.width  = SZ; cv.height = SZ;
  const ctx = cv.getContext('2d');
  ctx.drawImage(img, 0, 0, SZ, SZ);
  const { data } = ctx.getImageData(0, 0, SZ, SZ); // throws SecurityError if tainted

  const map = {};
  for (let i = 0; i < data.length; i += 4) {
    if (data[i + 3] < 80) continue;          // transparent pixels
    const r = data[i]     >> 3 << 3;          // quantise: steps of 8
    const g = data[i + 1] >> 3 << 3;
    const b = data[i + 2] >> 3 << 3;
    if (r + g + b < 45) continue;             // near-black (shadow artefacts)
    const key = `${r},${g},${b}`;
    map[key] = (map[key] || 0) + 1;
  }

  const top = Object.entries(map)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([k]) => {
      const [r, g, b] = k.split(',').map(Number);
      return '#' + [r, g, b].map(v => v.toString(16).padStart(2, '0')).join('');
    });

  return top.length >= 3 ? top : null;
}

function renderFallbackPalette(el, skin) {
  const BASE = {
    covert:     '#eb4b4b', classified: '#d32ce6',
    restricted: '#8847ff', milspec:    '#4b69ff',
    industrial: '#5e98d9', consumer:   '#b0c3d9',
  };
  const hex = BASE[skin.rarity] || '#4b69ff';
  const R = parseInt(hex.slice(1, 3), 16);
  const G = parseInt(hex.slice(3, 5), 16);
  const B = parseInt(hex.slice(5, 7), 16);
  const shades = [1.0, 0.75, 0.52, 0.34, 0.18].map(t => {
    const mix = v => Math.min(255, Math.round(v * t + 16 * (1 - t)));
    return '#' + [mix(R), mix(G), mix(B)].map(v => v.toString(16).padStart(2, '0')).join('');
  });
  renderSwatches(el, shades);
}

function renderSwatches(el, colors) {
  el.innerHTML = colors.map(hex => `
    <div class="swatch-item">
      <div class="swatch-dot" style="background:${hex}"></div>
      <span class="swatch-hex">${hex.toUpperCase()}</span>
    </div>`).join('');
}

function buildTrackGradient(minF, maxF) {
  const stops = [];
  if (minF > 0.001) stops.push(`${GRAY_ZONE} 0%`, `${GRAY_ZONE} ${(minF*100).toFixed(2)}%`);
  for (const z of FLOAT_ZONES) {
    const s = Math.max(z.min, minF);
    const e = Math.min(z.max, maxF);
    if (e <= s) continue;
    stops.push(`${ZONE_COLORS[z.wear]} ${(s*100).toFixed(2)}%`);
    stops.push(`${ZONE_COLORS[z.wear]} ${(e*100).toFixed(2)}%`);
  }
  if (maxF < 0.999) stops.push(`${GRAY_ZONE} ${(maxF*100).toFixed(2)}%`, `${GRAY_ZONE} 100%`);
  return stops.length ? `linear-gradient(90deg, ${stops.join(', ')})` : '';
}

function initFloatSlider(skin) {
  const slider = document.getElementById('floatSlider');
  const track  = document.getElementById('floatTrack');
  if (!slider || !track) return;

  const minF = skin.minFloat ?? 0.00;
  const maxF = skin.maxFloat ?? 1.00;

  track.style.background = buildTrackGradient(minF, maxF);

  slider.addEventListener('input', () => {
    let val = parseFloat(slider.value);
    if (val < minF) { val = minF; slider.value = String(minF); }
    if (val > maxF) { val = maxF; slider.value = String(maxF); }
    onFloatChange(skin, val);
  });

  onFloatChange(skin, parseFloat(slider.value));
}

function onFloatChange(skin, floatVal) {
  const wear = floatToWear(floatVal);

  const cat      = window._currentCategory || 'normal';
  const priceMap = cat === 'st' ? (skin.stWearPrices || {})
                 : cat === 'sv' ? (skin.svWearPrices || {})
                 : (skin.wearPrices || {});
  const entry = priceMap[wear];

  const dispEl = document.getElementById('floatDisplay');
  const wearEl = document.getElementById('floatWearTxt');
  const rowEl  = document.getElementById('floatPriceRow');
  const bigEl  = document.querySelector('.best-price-big');
  const subEl  = document.querySelector('.best-sub');
  const buyBtn = document.querySelector('.best-buy-btn');

  if (dispEl) dispEl.textContent = floatVal.toFixed(4);
  if (wearEl) wearEl.textContent = WN[wear] || wear;
  if (window._viewer) window._viewer.setFloat(floatVal);

  if (entry) {
    const catLabel = cat === 'st' ? 'StatTrak™ ' : cat === 'sv' ? 'Souvenir ' : '';
    if (rowEl) rowEl.innerHTML =
      `<span class="w-badge ${W_BADGE_CLS[wear]}">${escH(wear)}</span>` +
      `<span class="fpi-price">${escH(entry.priceStr)}</span>` +
      `<span class="fpi-src">white.market · live</span>`;
    if (bigEl)  bigEl.textContent = entry.priceStr;
    if (subEl)  subEl.innerHTML   = `${escH(catLabel)}${escH(WN[wear])} · white.market`;
    if (buyBtn) { buyBtn.href = entry.url; buyBtn.textContent = 'Buy on white.market →'; }
  } else {
    if (rowEl) rowEl.innerHTML =
      `<span class="w-badge ${W_BADGE_CLS[wear]}">${escH(wear)}</span>` +
      `<span class="fpi-unavail">Indisponible pour ce float</span>`;
  }

  // Sync Active Offers panel with current wear + variant category
  const offersBody = document.getElementById('offersBody');
  const offersCnt  = document.getElementById('offersCnt');
  if (offersBody) {
    offersBody.innerHTML = buildOffersForWear(skin, cat, wear);
    const n = offersBody.querySelectorAll('.offer-row:not(.oos)').length;
    if (offersCnt) offersCnt.textContent = n + ' marketplace' + (n !== 1 ? 's' : '');
  }
}
