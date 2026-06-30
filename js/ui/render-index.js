// Responsibility: render all index-page views (category grid, weapon grid, skin cards, trending)

function fmtPrice(n) {
  if (!n || n <= 0) return '—';
  return n >= 1000 ? '€' + Math.round(n).toLocaleString('de-DE') : '€' + n.toFixed(2);
}

function wearRange(vals) {
  if (!vals.length) return null;
  const nums = vals.map(v => v.priceEur);
  const min  = Math.min(...nums);
  const max  = Math.max(...nums);
  return nums.length > 1
    ? `${fmtPrice(min)}<span class="range-dash"> – </span>${fmtPrice(max)}`
    : fmtPrice(min);
}

function skinCard(skin) {
  const hasVariant = skin.variant && skin.variant !== 'Vanilla';
  const title      = hasVariant ? `${skin.name} | ${skin.variant}` : skin.name;

  const wearVals = Object.values(skin.wearPrices   || {}).filter(v => v.priceEur > 0);
  const stVals   = Object.values(skin.stWearPrices || {}).filter(v => v.priceEur > 0);
  const svVals   = Object.values(skin.svWearPrices || {}).filter(v => v.priceEur > 0);

  const normalR = wearRange(wearVals);
  const stR     = wearRange(stVals);
  const svR     = wearRange(svVals);

  let priceBlock;
  if (normalR || stR || svR) {
    const lines = [];
    if (normalR) lines.push(`<div class="cpl"><span class="cpl-label">Normal</span><span class="cpl-range">${normalR}</span></div>`);
    if (stR)     lines.push(`<div class="cpl st"><span class="cpl-label">StatTrak</span><span class="cpl-range">${stR}</span></div>`);
    if (svR)     lines.push(`<div class="cpl sv"><span class="cpl-label">Souvenir</span><span class="cpl-range">${svR}</span></div>`);
    priceBlock = `<div class="card-price-lines">${lines.join('')}</div>`;
  } else {
    const fp = (skin.prices || [])
      .map(p => ({ ...p, priceNum: p.priceNum || parseFloat(String(p.price || '').replace(/[^\d.]/g, '')) || 0 }))
      .filter(p => p.priceNum > 0)
      .sort((a, b) => a.priceNum - b.priceNum)[0];
    priceBlock = fp
      ? `<div class="card-price-lines"><div class="cpl"><span class="cpl-label">Normal</span><span class="cpl-range">${fmtPrice(fp.priceNum)}</span></div></div>`
      : `<div class="card-no-price">No price data</div>`;
  }

  return `
  <div class="skin-card r-${skin.rarity}" onclick="openSkin('${skin.id}')">
    <div class="rarity-stripe stripe-${skin.rarity}"></div>
    <div class="skin-card-inner">
      <div class="skin-img-wrap bg-${skin.rarity}">
        <img class="skin-img" src="${skin.image}" alt="${escHtml(title)}" loading="lazy" onerror="this.style.opacity='0.08'"/>
      </div>
      <div class="skin-name">${escHtml(title)}</div>
      ${priceBlock}
    </div>
  </div>`;
}

// Category card CSS class mapping
const CAT_CLASS = {
  rifles:  'rifles',
  sniper:  'snipers',
  pistol:  'pistols',
  smg:     'smgs',
  knife:   'knives',
  gloves:  'gloves',
};

function renderCatGrid() {
  const grid = document.getElementById('catGrid');
  if (!grid) return;
  grid.innerHTML = CAT_DEFS.map(cat => {
    const catSkins = skinsForCat(cat.id);
    const wcClass  = CAT_CLASS[cat.id] || '';

    // Collect up to 3 weapon images
    const previewImgs = [];
    for (const w of cat.weapons) {
      if (previewImgs.length >= 3) break;
      const img = weaponImg(w);
      if (img) previewImgs.push(img);
    }

    const imgsHtml = previewImgs.length
      ? previewImgs.map(src => `<img src="${src}" alt="" loading="lazy">`).join('')
      : `<div class="ph-icon">${cat.emoji || '◈'}</div>`;

    const skinCount = catSkins.length;
    const statsHtml = `
      <div class="wcard-stats">
        <strong>${cat.weapons.length}</strong> <span style="color:var(--muted2)">weapons</span>
        ${skinCount ? `<span class="sep">·</span><strong>${skinCount.toLocaleString()}</strong> <span style="color:var(--muted2)">skins</span>` : ''}
      </div>`;

    return `
    <div class="wcard ${wcClass}" onclick="goCategory('${cat.id}')">
      <span class="br tr"></span><span class="br br2"></span>
      <div class="wcard-imgs">${imgsHtml}</div>
      <div class="wcard-title">${cat.label}</div>
      <div class="wcard-sub">${cat.desc}</div>
      ${statsHtml}
      <div class="wcard-cta">Browse all</div>
    </div>`;
  }).join('');

  // Update browse meta
  const allSkinCount = (window.API && window.API.state.allSkins.length) || 0;
  const meta = document.getElementById('browseMeta');
  if (meta) meta.textContent = `${CAT_DEFS.length} CATEGORIES · ${allSkinCount.toLocaleString()} SKINS`;
}

function refreshCatCards() {
  if (VIEW === 'home') renderCatGrid();
}

function renderWeaponGrid(catId) {
  const cat  = CAT_BY_ID[catId];
  const grid = document.getElementById('weaponGrid');
  if (!cat || !grid) return;
  grid.innerHTML = cat.weapons.map(w => {
    const img     = weaponImg(w);
    const count   = skinsForWeapon(w).length;
    const imgHtml = img
      ? `<img src="${img}" alt="${w}" loading="lazy">`
      : `<div class="weapon-card-img-ph">${cat.emoji}</div>`;
    return `
    <div class="weapon-card" onclick="goWeapon('${w.replace(/'/g,"\\'")}', '${catId}')">
      <div class="weapon-card-img-wrap">${imgHtml}</div>
      <div class="weapon-card-name">${w}</div>
      <div class="weapon-card-count">${count ? count + ' skins' : '—'}</div>
      <div class="weapon-card-cta">View skins →</div>
    </div>`;
  }).join('');
}

function refreshWeaponCards() {
  if (VIEW === 'cat' && VIEW_CAT_ID) renderWeaponGrid(VIEW_CAT_ID);
}

function updateSkinsHeader() {
  const count = SKIN_LIST.length;
  const rc = document.getElementById('myResultCount');
  if (rc) rc.textContent = count.toLocaleString();
  const sub = document.getElementById('skins-sub');
  if (sub) sub.textContent = count.toLocaleString() + ' skins';
}

function renderSkinPage() {
  const grid = document.getElementById('skinGrid');
  if (!grid) return;
  const start = (SKIN_PAGE - 1) * PER_PAGE;
  const slice = SKIN_LIST.slice(start, start + PER_PAGE);

  if (!SKIN_LIST.length && allSkins().length === 0) {
    grid.innerHTML = `<div class="empty-state"><div class="empty-icon">◈</div><div class="empty-text">Loading skins…</div><div class="empty-sub">Fetching from ByMykel</div></div>`;
  } else if (!SKIN_LIST.length) {
    grid.innerHTML = `<div class="empty-state"><div class="empty-icon">◈</div><div class="empty-text">No skins found</div><div class="empty-sub">Try a different search or category</div></div>`;
  } else {
    grid.innerHTML = slice.map(skinCard).join('');
  }
  updateSkinsHeader();
  renderMyPagination(SKIN_LIST.length);
}

function renderMyPagination(total) {
  const el = document.getElementById('myPagination');
  if (!el) return;
  const totalPages = Math.ceil(total / PER_PAGE);
  if (totalPages <= 1) { el.innerHTML = ''; return; }
  const p  = SKIN_PAGE;
  let html = pBtn('← Prev', p - 1, p === 1, 'nav');
  for (const pg of pageRange(p, totalPages)) {
    html += pg === '…'
      ? `<button class="page-btn page-btn-ellipsis" disabled>…</button>`
      : pBtn(pg, pg, false);
  }
  html += pBtn('Next →', p + 1, p === totalPages, 'nav');
  el.innerHTML = html;
}

function pBtn(label, target, disabled, variant) {
  const active = !disabled && typeof target === 'number' && target === SKIN_PAGE ? ' active' : '';
  const nav    = variant === 'nav' ? ' page-btn-nav' : '';
  const dis    = disabled ? ' disabled' : '';
  const click  = disabled ? '' : ` onclick="skinGoPage(${target})"`;
  return `<button class="page-btn${nav}${active}"${dis}${click}>${label}</button>`;
}

function renderTrending() {
  const rail = document.getElementById('trendingRail');
  if (!rail) return;
  const skins = allSkins();
  if (!skins.length) return;

  // Pick top skins by price with images
  const picks = [...skins]
    .filter(s => s.image && s.priceNum > 0)
    .sort((a, b) => b.priceNum - a.priceNum)
    .slice(0, 8);
  if (!picks.length) return;

  const RARITY_COLOR = {
    covert:     'var(--covert)',
    classified: 'var(--classified)',
    restricted: 'var(--restricted)',
    milspec:    'var(--milspec)',
  };

  rail.innerHTML = picks.map(s => {
    const hasVariant = s.variant && s.variant !== 'Vanilla';
    const label  = hasVariant ? `${s.name} | ${s.variant}` : s.name;
    const color  = RARITY_COLOR[s.rarity] || 'var(--accent)';
    const bestP  = (s.prices || [])
      .map(p => ({ ...p, n: p.priceNum || parseFloat(String(p.price||'').replace(/[^\d.]/g,''))||0 }))
      .filter(p => p.n > 0).sort((a,b) => a.n - b.n)[0];
    const market = bestP ? (bestP.market || bestP.source || 'Market') : '';

    return `
    <article class="drop-card" style="--card-color:${color};--card-glow:color-mix(in srgb, ${color} 25%, transparent)" onclick="openSkin('${s.id}')">
      <div class="drop-card-shine"></div>
      <div class="drop-card-img">
        <img src="${s.image}" alt="${escHtml(label)}" loading="lazy" onerror="this.src='';this.parentNode.innerHTML='<div class=\\'ph\\'><span class=\\'ic\\'>◈</span>${escHtml(s.name)}</div>'">
      </div>
      <div class="drop-card-stripe"></div>
      <div class="drop-card-body">
        <div class="drop-card-meta">
          <span class="rar">${(s.rarity || 'skin').toUpperCase()}</span>
        </div>
        <div class="drop-card-name">${escHtml(s.name)} <span class="v">${hasVariant ? escHtml(s.variant) : ''}</span></div>
        <div class="drop-card-foot">
          <div>
            <div class="drop-card-price">${bestP ? fmtPrice(bestP.n) : '—'}</div>
            <div class="drop-card-mkt">${escHtml(market)}</div>
          </div>
          <div class="drop-card-delta up">↗</div>
        </div>
      </div>
    </article>`;
  }).join('');

  // Update meta
  const meta = document.getElementById('trendingMeta');
  if (meta) meta.textContent = `UPDATED · ${picks.length} ITEMS`;
}
