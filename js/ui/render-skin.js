// Responsibility: build all HTML for the skin detail page

const W_BADGE_CLS = { FN:'w-fn', MW:'w-mw', FT:'w-ft', WW:'w-ww', BS:'w-bs' };

const MP_META = {
  'white.market': { logo:'WM', logoBg:'#0b1a12', logoColor:'#00d882', stars: 4.7, reviews:'2.1k', partner: true  },
  'CSFloat':      { logo:'CF', logoBg:'#0d1520', logoColor:'#5b8af5', stars: 4.6, reviews:'5.2k', partner: false },
  'DMarket':      { logo:'DM', logoBg:'#0c1624', logoColor:'#4a9eff', stars: 4.5, reviews:'8.3k', partner: false },
};

const MP_SOURCE_META = {
  skinport:  { name: 'Skinport',  abbr: 'SP', bg: '#0d1822', color: '#f79a3f' },
  csfloat:   { name: 'CSFloat',   abbr: 'CF', bg: '#0d1520', color: '#5b8af5' },
  dmarket:   { name: 'DMarket',   abbr: 'DM', bg: '#0c1624', color: '#4a9eff' },
  shadowpay: { name: 'Shadowpay', abbr: 'SH', bg: '#0d1a14', color: '#2ecc71' },
  waxpeer:   { name: 'Waxpeer',   abbr: 'WP', bg: '#14100a', color: '#e88b34' },
  bitskins:  { name: 'BitSkins',  abbr: 'BK', bg: '#0d0d20', color: '#7b68ee' },
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

  const hasST = WO.some(w => (skin.stWearPrices||{})[w]);
  const canSouvenir = skin.category !== 'knife' && skin.category !== 'glove';
  const hasSV = canSouvenir && WO.some(w => (skin.svWearPrices||{})[w]);

  document.title = skin.name + (skin.variant ? ' | ' + skin.variant : '') + ' — CSSkins';
  document.getElementById('bcCat').textContent  = catLabel;
  document.getElementById('bcName').textContent = skin.name + (skin.variant ? ' | ' + skin.variant : '');

  const wp       = skin.wearPrices || {};
  const wpVals   = Object.values(wp).filter(e => e && e.priceEur > 0);
  const bestEntry = wpVals.length
    ? wpVals.reduce((a,b) => a.priceEur<=b.priceEur ? a : b)
    : skin.prices?.[0] || null;
  const bestStr  = bestEntry?.priceStr || bestEntry?.price || '—';
  const bestSite = bestEntry?.url?.includes('white.market') ? 'white.market' : (skin.prices?.[0]?.site || 'Market');
  const bestUrl  = bestEntry?.url || '#';

  const catSwitchHtml = (hasST || hasSV) ? `
  <div class="cat-switch" id="catSwitch">
    <button class="cat-btn active" data-cat="normal" onclick="setCategory('normal')">Normal</button>
    ${hasST ? '<button class="cat-btn st" data-cat="st" onclick="setCategory(\'st\')">StatTrak™</button>' : ''}
    ${hasSV ? '<button class="cat-btn sv" data-cat="sv" onclick="setCategory(\'sv\')">Souvenir</button>' : ''}
  </div>` : '';

  const sectionLabelTxt = [rarLabel, catLabel, skin.collection].filter(Boolean).join(' · ');

  document.getElementById('root').innerHTML = `

<section class="title-band reveal">
  <div class="section-label">// ${escH(sectionLabelTxt)}</div>
  <h1 class="skin-h1">
    <span>${escH(skin.name)}</span>
    ${skin.variant ? `<span class="pipe">|</span><span class="variant">${escH(skin.variant)}</span>` : ''}
  </h1>
  <div class="badges">
    <span class="badge ${escH(skin.rarity||'')}">● ${escH(rarLabel)}</span>
    ${wearFull ? `<span class="badge">${escH(wearFull)}</span>` : ''}
    ${skin.collection ? `<span class="badge">${escH(skin.collection)}</span>` : ''}
  </div>
</section>

<section class="content-grid">
  <div class="left">

    <!-- VIEWER CARD -->
    <div class="card viewer-card reveal">
      <div class="brackets"><span class="br tl"></span><span class="br tr"></span><span class="br bl"></span><span class="br br"></span></div>
      <div class="view-tabs" id="viewTabs">
        <button class="view-tab active" data-tab="wear" onclick="setViewTab('wear')">Wear</button>
        <button class="view-tab" data-tab="3d" onclick="setViewTab('3d')">3D View</button>
      </div>
      <div id="viewer-stage">
        <div class="viewer-hud-tl">// IMAGE_VIEW</div>
        <div class="viewer-hud-tr"><span class="dot green"></span> Live</div>
        <img id="skinImg"
             src="${escA(skin.image)}"
             alt="${escA((skin.name||'') + (skin.variant ? ' | '+skin.variant : ''))}"
             onerror="this.style.opacity='.08'"
             onclick="toggleZoom()" />
        <div id="inspectFrame" class="inspect-frame"></div>
        <div class="viewer-overlay-grid"></div>
        <svg class="viewer-reticle" width="44" height="44" viewBox="0 0 44 44" fill="none">
          <circle cx="22" cy="22" r="11" stroke="#ff2965" stroke-width="0.8"/>
          <line x1="22" y1="0" x2="22" y2="6" stroke="#ff2965" stroke-width="0.8"/>
          <line x1="22" y1="38" x2="22" y2="44" stroke="#ff2965" stroke-width="0.8"/>
          <line x1="0" y1="22" x2="6" y2="22" stroke="#ff2965" stroke-width="0.8"/>
          <line x1="38" y1="22" x2="44" y2="22" stroke="#ff2965" stroke-width="0.8"/>
        </svg>
        <div class="img-btns" id="imgBtns">
          <button class="img-btn" onclick="toggleMirror()">↺ Flip</button>
          <button class="img-btn" onclick="copyURL()">⊡ Share</button>
        </div>
        <div class="viewer-hint">Click to zoom</div>
      </div>
      <div class="viewer-bar">
        <div class="left-info">Float: <strong id="floatDisplay">${escH(floatStr)}</strong> · <span id="floatWearTxt">${escH(wearFull)}</span></div>
        <div class="right-src"><span class="dot green"></span>white.market // live</div>
      </div>
    </div>

    <!-- FLOAT CARD -->
    <div class="card float-card reveal">
      <div class="float-card-top">
        <div class="section-label" style="margin-bottom:0">// FLOAT_VALUE</div>
        <span class="float-card-minmax">Min ${minFloat.toFixed(2)} · Max ${maxFloat.toFixed(2)}</span>
      </div>
      <div class="float-row">
        <div class="float-num" id="floatNum">${escH(floatStr)}</div>
        <div class="float-wear" id="floatWear">${escH(wearFull)}</div>
      </div>
      <div class="float-track-wrap">
        <div class="float-grad"></div>
        <span class="float-zone-marker" style="left:7%"></span>
        <span class="float-zone-marker" style="left:15%"></span>
        <span class="float-zone-marker" style="left:38%"></span>
        <span class="float-zone-marker" style="left:45%"></span>
        <input type="range" class="float-slider" id="floatSlider"
               min="0" max="1" step="0.0001" value="${floatNum}" />
      </div>
      <div class="float-ticks"><span>FN</span><span>MW</span><span>FT</span><span>WW</span><span>BS</span></div>
      <div class="float-price-row" id="floatPriceRow"></div>
    </div>

    <!-- PRICES BY WEAR -->
    <div class="card prices-card reveal">
      <div class="card-head">
        <span class="label">// Prices by Wear</span>
        <span class="meta"><span class="dot green"></span>white.market · live</span>
      </div>
      <div id="wearRowsBody">${buildWearRows(skin)}</div>
    </div>

  </div>

  <aside class="right">
    ${catSwitchHtml}

    <!-- BEST PRICE -->
    <div class="best-card reveal">
      <div class="brackets green"><span class="br tl"></span><span class="br tr"></span><span class="br bl"></span><span class="br br"></span></div>
      <div class="best-eyebrow"><span class="dot green"></span>● Best_Price_Right_Now</div>
      <div class="best-price-big" id="bestPriceBig">${escH(bestStr)}</div>
      <div class="best-sub" id="bestSub">Cheapest available · <strong>${escH(bestSite)}</strong></div>
      <a class="best-buy-btn" id="bestBuyBtn" href="${escA(bestUrl)}" target="_blank" rel="noopener">Buy on ${escH(bestSite)} →</a>
    </div>

    <!-- ACTIVE OFFERS -->
    <div class="card offers-card reveal">
      <div class="card-head">
        <span class="label">// Active_Offers</span>
        <span class="meta" id="offersCnt"></span>
      </div>
      <div id="offersBody">${buildOffersForWear(skin, 'normal', floatToWear(floatNum))}</div>
    </div>

    <!-- SKIN INFO -->
    <div class="card reveal">
      <div class="card-head"><span class="label">// Skin_Data</span></div>
      ${buildSkinInfo(skin)}
    </div>

    <!-- SPARKLINE (simulated) -->
    <div class="card spark-card reveal">
      <div class="spark-head">
        <span class="label">// Price_History · 30D</span>
        <span class="delta down" id="sparkDelta">—</span>
      </div>
      <svg class="spark-svg" id="sparkSvg" viewBox="0 0 320 80" preserveAspectRatio="none">
        <defs>
          <linearGradient id="spark-fill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stop-color="#00ff88" stop-opacity="0.32"/>
            <stop offset="100%" stop-color="#00ff88" stop-opacity="0"/>
          </linearGradient>
        </defs>
        <path id="sparkFillPath" d="" fill="url(#spark-fill)" opacity="0"></path>
        <path id="sparkLinePath" class="spark-path" d="" fill="none" stroke="#00ff88" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" style="filter:drop-shadow(0 0 6px rgba(0,255,136,0.55))"></path>
        <circle id="sparkDot" class="spark-dot" cx="0" cy="0" r="3" fill="#00ff88" style="filter:drop-shadow(0 0 8px rgba(0,255,136,0.55))"></circle>
      </svg>
    </div>

  </aside>
</section>

<!-- SIMILAR SKINS -->
<section class="similar-section reveal" id="similarSection">
  <div class="similar-head">
    <div>
      <div class="section-label">// Similar_Drops</div>
      <h3 class="similar-title">You might also like</h3>
    </div>
    <a href="index.html${skin.rarity ? '?rarity=' + encodeURIComponent(skin.rarity) : ''}" class="see-all" id="seeAllLink">View all ${escH(rarLabel)} →</a>
  </div>
  <div class="similar-row" id="similarRow"></div>
</section>

<!-- EXTRA SECTIONS -->
<div class="extra-sections">
  <div class="extra-card" id="mpPricesCard">
    <div class="extra-head">Prix par marketplace</div>
    <div id="mpPricesBody" class="mp-loader-wrap"><div class="mp-spin"></div></div>
  </div>
  <div class="extra-card" id="colorsCard">
    <div class="extra-head">Colors</div>
    <div class="colors-swatches" id="colorsSwatches"><span class="swatch-loading">Extracting colors…</span></div>
  </div>
  ${buildContainers(skin)}
  ${buildGallery(skin)}
</div>`;

  // Offer count
  const offN = document.querySelectorAll('#offersBody .offer-row:not(.oos)').length;
  const offCnt = document.getElementById('offersCnt');
  if (offCnt) offCnt.textContent = offN + ' marketplace' + (offN !== 1 ? 's' : '');

  initFloatSlider(skin);
  initColors(skin);
  initContainers(skin);
  initMarketplacePrices(skin);
  initSparkline(skin);
  initSimilar(skin);
  initReveal();
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
      <a class="wear-row best" href="${escA(p.url)}" target="_blank" rel="noopener">
        <span class="wear-badge w-ft">—</span>
        <span class="wear-name">${escH(p.site||'Market')}</span>
        <span class="wear-price">${escH(p.price||'—')}</span>
        <span class="wear-buy-link">Buy →</span>
      </a>`).join('');
  }

  const wearRow = (w, p, prefix, isBest, badgeClass) => {
    const cls = `wear-row${prefix ? ' ' + prefix + '-row' : ''}${isBest ? ' best' : ''}`;
    const name = prefix === 'st' ? 'StatTrak™ ' + WN[w] : prefix === 'sv' ? 'Souvenir ' + WN[w] : WN[w];
    if (!p) return `
      <div class="wear-row unavail">
        <span class="wear-badge ${W_BADGE_CLS[w]}">${w}</span>
        <span class="wear-name">${escH(name)}</span>
        <span class="wear-na">—</span>
      </div>`;
    return `
    <a class="${cls}" href="${escA(p.url)}" target="_blank" rel="noopener">
      <span class="wear-badge ${W_BADGE_CLS[w]}">${w}</span>
      <span class="wear-name">${escH(name)}</span>
      <span class="wear-price">${escH(p.priceStr)}</span>
      ${isBest ? `<span class="wear-best-tag${prefix ? ' ' + prefix : ''}">BEST</span>` : ''}
      <span class="wear-buy-link">Buy →</span>
    </a>`;
  };

  let html = '';

  if (hasNormal) {
    const have = WO.filter(w => wp[w]);
    const best = have.reduce((a,b) => wp[a].priceEur <= wp[b].priceEur ? a : b);
    html += WO.map(w => wearRow(w, wp[w], '', w === best)).join('');
  }
  if (hasST) {
    const have = WO.filter(w => sp[w]);
    const best = have.length ? have.reduce((a,b) => sp[a].priceEur <= sp[b].priceEur ? a : b) : null;
    html += `<div class="w-divider st">StatTrak™</div>`;
    html += WO.map(w => wearRow(w, sp[w], 'st', w === best)).join('');
  }
  if (hasSV) {
    const have = WO.filter(w => sv[w]);
    const best = have.length ? have.reduce((a,b) => sv[a].priceEur <= sv[b].priceEur ? a : b) : null;
    html += `<div class="w-divider sv">Souvenir</div>`;
    html += WO.map(w => wearRow(w, sv[w], 'sv', w === best)).join('');
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

async function initMarketplacePrices(skin) {
  const body = document.getElementById('mpPricesBody');
  if (!body) return;

  const wearFull = WN[skin.wear] || skin.wear || '';
  const mhn = skin.name
    + (skin.variant ? ' | ' + skin.variant : '')
    + (wearFull ? ' (' + wearFull + ')' : '');

  const API_BASE = (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')
    ? 'https://csskinsv2.vercel.app'
    : window.location.origin;
  const url = API_BASE + '/api/prices/all?market_hash_name=' + encodeURIComponent(mhn);
  console.log('[mp-prices] market_hash_name:', mhn);
  console.log('[mp-prices] url:', url);

  try {
    const r = await fetch(url);
    const raw = await r.text();
    console.log('[mp-prices] status:', r.status);
    console.log('[mp-prices] raw body:', raw);
    const data = JSON.parse(raw);

    if (!data.prices || !data.prices.length) {
      body.innerHTML = '<div class="mp-empty">Prix non disponible</div>';
      return;
    }

    const sorted = [...data.prices].sort((a, b) => (a.price ?? Infinity) - (b.price ?? Infinity));
    const cheapest = sorted[0]?.source;

    body.innerHTML = sorted.map(p => {
      const m = MP_SOURCE_META[p.source] || { name: p.source, abbr: p.source.slice(0,2).toUpperCase(), bg: '#1a1f2a', color: '#7b8698' };
      const priceStr = p.price != null
        ? (p.currency === 'EUR' ? '€' : '$') + p.price.toFixed(2)
        : '—';
      const isCheapest = p.source === cheapest;
      return `
      <div class="mp-row${isCheapest ? ' mp-best' : ''}">
        <div class="mp-logo" style="background:${m.bg};color:${m.color}">${m.abbr}</div>
        <div class="mp-name">
          ${escH(m.name)}
          ${isCheapest ? '<span class="mp-cheapest-badge">MOINS CHER</span>' : ''}
        </div>
        <div class="mp-price">${escH(priceStr)}</div>
        <a class="mp-buy-btn" href="${escA(p.url || '#')}" target="_blank" rel="noopener">Acheter →</a>
      </div>`;
    }).join('');
  } catch(e) {
    console.error('[mp-prices] error:', e);
    body.innerHTML = `<div class="mp-empty" style="text-align:left;padding:16px 20px">
      <div style="color:#eb4b4b;font-weight:600;margin-bottom:6px">Erreur de chargement</div>
      <div style="font-size:11px;color:var(--muted);font-family:monospace;white-space:pre-wrap">${escH(e.message || String(e))}</div>
      <div style="font-size:11px;color:var(--muted2);margin-top:6px">URL: ${escH(url)}</div>
    </div>`;
  }
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
  if (!slider) return;

  const minF = skin.minFloat ?? 0.00;
  const maxF = skin.maxFloat ?? 1.00;

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
  const wearName = WN[wear] || wear;

  const cat      = window._currentCategory || 'normal';
  const priceMap = cat === 'st' ? (skin.stWearPrices || {})
                 : cat === 'sv' ? (skin.svWearPrices || {})
                 : (skin.wearPrices || {});
  const entry = priceMap[wear];

  // Update float display elements
  const dispEl   = document.getElementById('floatDisplay');
  const wearTxt  = document.getElementById('floatWearTxt');
  const floatNum = document.getElementById('floatNum');
  const floatWr  = document.getElementById('floatWear');
  const rowEl    = document.getElementById('floatPriceRow');
  const bigEl    = document.getElementById('bestPriceBig');
  const subEl    = document.getElementById('bestSub');
  const buyBtn   = document.getElementById('bestBuyBtn');

  if (dispEl)   dispEl.textContent   = floatVal.toFixed(4);
  if (wearTxt)  wearTxt.textContent  = wearName;
  if (floatNum) floatNum.textContent = floatVal.toFixed(4);
  if (floatWr)  floatWr.textContent  = wearName;
  if (window._viewer) window._viewer.setFloat(floatVal);

  if (entry) {
    const catLabel = cat === 'st' ? 'StatTrak™ ' : cat === 'sv' ? 'Souvenir ' : '';
    if (rowEl) rowEl.innerHTML =
      `<span class="wear-badge w-${wear.toLowerCase()}">${escH(wear)}</span>` +
      `<span class="fpi-price">${escH(entry.priceStr)}</span>` +
      `<span class="fpi-src">white.market · live</span>`;
    if (bigEl)  bigEl.textContent = entry.priceStr;
    if (subEl)  subEl.innerHTML   = `${escH(catLabel)}${escH(wearName)} · <strong>white.market</strong>`;
    if (buyBtn) { buyBtn.href = entry.url || '#'; buyBtn.textContent = 'Buy on white.market →'; }
  } else {
    if (rowEl) rowEl.innerHTML =
      `<span class="wear-badge w-${wear.toLowerCase()}">${escH(wear)}</span>` +
      `<span class="fpi-unavail">Unavailable for this float</span>`;
  }

  // Sync Active Offers panel
  const offersBody = document.getElementById('offersBody');
  const offersCnt  = document.getElementById('offersCnt');
  if (offersBody) {
    offersBody.innerHTML = buildOffersForWear(skin, cat, wear);
    const n = offersBody.querySelectorAll('.offer-row:not(.oos)').length;
    if (offersCnt) offersCnt.textContent = n + ' marketplace' + (n !== 1 ? 's' : '');
  }
}

function initSparkline(skin) {
  // Generate a plausible sparkline from bestEntry price
  const base = skin.priceNum || 10;
  const data = Array.from({ length: 30 }, (_, i) => {
    const noise = (Math.sin(i * 0.7) * 0.15 + Math.sin(i * 0.3) * 0.12 + (Math.random() - 0.5) * 0.1);
    return Math.max(base * 0.6, base * (1 + noise));
  });
  data[data.length - 1] = base;

  const lineEl = document.getElementById('sparkLinePath');
  const fillEl = document.getElementById('sparkFillPath');
  const dotEl  = document.getElementById('sparkDot');
  const delta  = document.getElementById('sparkDelta');
  if (!lineEl) return;

  const W = 320, H = 80, padY = 6;
  const min = Math.min(...data), max = Math.max(...data);
  const range = max - min || 1;
  const step = W / (data.length - 1);
  const pts = data.map((v, i) => ({ x: i * step, y: H - padY - ((v - min) / range) * (H - padY * 2) }));
  const linePath = pts.map((p, i) => (i ? 'L' : 'M') + p.x.toFixed(1) + ',' + p.y.toFixed(1)).join(' ');
  const fillPath = linePath + ` L${W},${H} L0,${H} Z`;

  lineEl.setAttribute('d', linePath);
  if (fillEl) fillEl.setAttribute('d', fillPath);
  if (dotEl) { dotEl.setAttribute('cx', pts[pts.length-1].x); dotEl.setAttribute('cy', pts[pts.length-1].y); }

  const pctChange = ((data[data.length-1] - data[0]) / data[0]) * 100;
  if (delta) {
    const up = pctChange >= 0;
    delta.textContent = (up ? '▲ +' : '▼ ') + Math.abs(pctChange).toFixed(1) + '%';
    delta.className = 'delta ' + (up ? 'up' : 'down');
  }

  requestAnimationFrame(() => {
    const len = lineEl.getTotalLength?.() || 200;
    lineEl.style.strokeDasharray = len;
    lineEl.style.strokeDashoffset = len;
    const io = new IntersectionObserver(entries => {
      entries.forEach(e => {
        if (e.isIntersecting) {
          lineEl.style.strokeDashoffset = '0';
          if (fillEl) { fillEl.style.transition = 'opacity 1.4s ease-out 0.3s'; fillEl.style.opacity = '1'; }
          io.disconnect();
        }
      });
    }, { threshold: 0.2 });
    io.observe(lineEl);
  });
}

function initSimilar(skin) {
  const row = document.getElementById('similarRow');
  if (!row) return;
  const RARITY_COLOR = { covert:'var(--covert)', classified:'var(--classified)', restricted:'var(--restricted)', milspec:'var(--milspec)', industrial:'#5e98d9', consumer:'#b0c3d9' };
  const fmt = n => n >= 1000 ? '€' + Math.round(n).toLocaleString('de-DE') : '€' + n.toFixed(2);

  const all  = (window.API?.state?.allSkins || []);
  const pool = all.filter(s => s.id !== skin.id && s.image && s.priceNum > 0);

  // Same rarity (color) is the primary signal — fall back progressively so the
  // section is virtually always populated, instead of disappearing when no
  // other skin shares the exact weapon name.
  let similar = pool.filter(s => s.rarity === skin.rarity && s.category === skin.category);
  if (similar.length < 4) similar = pool.filter(s => s.rarity === skin.rarity);
  if (similar.length < 4) similar = pool.filter(s => s.category === skin.category);

  similar = similar
    .sort((a, b) => Math.abs(a.priceNum - skin.priceNum) - Math.abs(b.priceNum - skin.priceNum))
    .slice(0, 10);

  if (!similar.length) {
    const sec = document.getElementById('similarSection');
    if (sec) sec.style.display = 'none';
    return;
  }

  row.innerHTML = similar.map(s => {
    const color = RARITY_COLOR[s.rarity] || 'var(--accent)';
    const label = s.variant && s.variant !== 'Vanilla' ? `${s.name} | ${s.variant}` : s.name;
    return `
    <div class="sim-card" style="--rarity:${color}" onclick="openSkinPage('${escA(s.id)}')">
      <div class="sim-card-img">
        <img src="${escA(s.image)}" alt="${escA(label)}" loading="lazy" onerror="this.style.opacity='.08'">
      </div>
      <div class="sim-card-body">
        <div class="sim-card-name">${escH(s.variant || s.name)}</div>
        <div class="sim-card-row">
          <span class="sim-card-rarity">${escH(s.rarity||'')}</span>
          <span class="sim-card-price">${fmt(s.priceNum)}</span>
        </div>
      </div>
    </div>`;
  }).join('');
}

function openSkinPage(id) {
  const skin = (window.API?.state?.allSkins || []).find(s => s.id === id);
  if (!skin) return;
  try { sessionStorage.setItem('csskins_detail', JSON.stringify(skin)); } catch(_) {}
  location.href = 'skin.html?skin=' + encodeURIComponent(id);
}

function initReveal() {
  const io = new IntersectionObserver(entries => {
    entries.forEach(e => {
      if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); }
    });
  }, { threshold: 0.1, rootMargin: '0px 0px -30px 0px' });
  document.querySelectorAll('.reveal').forEach(el => io.observe(el));
}
