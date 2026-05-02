// Responsibility: index page state machine — API bridge, VIEW navigation, skin list interactions

// ─── API state ────────────────────────────────────────────────────────────────
const _apiState = {
  allSkins:     [],
  filtered:     [],
  page:         1,
  search:       '',
  category:     'all',
  sort:         'name',
  pricesLoaded: false,
  loading:      false,
};

window.API = {
  state:       _apiState,
  goToPage,
  search:      q => { _apiState.search   = q; applyApiFilters(); },
  setCategory: c => { _apiState.category = c; applyApiFilters(); },
  setSort:     s => { _apiState.sort     = s; applyApiFilters(); },
};

function applyApiFilters() {
  let list = _apiState.allSkins;

  if (_apiState.search) {
    const q = _apiState.search.toLowerCase();
    list = list.filter(s => (s.name + ' ' + s.variant).toLowerCase().includes(q));
  }

  const cat = _apiState.category;
  if (cat !== 'all') {
    list = list.filter(s => s.rarity === cat || s.wear === cat || s.category === cat);
  }

  if (_apiState.sort === 'name') {
    list = [...list].sort((a, b) => (a.name + a.variant).localeCompare(b.name + b.variant));
  } else if (_apiState.sort === 'price') {
    list = [...list].sort((a, b) => {
      if (a.priceNum > 0 && b.priceNum > 0) return a.priceNum - b.priceNum;
      if (a.priceNum > 0) return -1;
      if (b.priceNum > 0) return  1;
      return (a.name + a.variant).localeCompare(b.name + b.variant);
    });
  } else if (_apiState.sort === 'price-desc') {
    list = [...list].sort((a, b) => b.priceNum - a.priceNum);
  }

  _apiState.filtered = list;
  _apiState.page     = 1;
  renderApiPage();
}

function renderApiPage() {
  const { filtered, page } = _apiState;
  const slice = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);
  if (typeof window.renderSkins === 'function') window.renderSkins(slice);
  const rc = document.getElementById('resultCount');
  if (rc) rc.textContent = filtered.length.toLocaleString();
  renderApiPagination(filtered.length);
}

function goToPage(p) {
  const max = Math.ceil(_apiState.filtered.length / PAGE_SIZE);
  if (p < 1 || p > max) return;
  _apiState.page = p;
  renderApiPage();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

// ─── VIEW state ───────────────────────────────────────────────────────────────
var VIEW           = 'home';
var VIEW_CAT_ID    = null;
var VIEW_WEAPON    = null;
var VIEW_SEARCH    = '';
var VIEW_FILTER_FN = null;

var SKIN_PAGE  = 1;
var SKIN_SORT  = 'date';
var SKIN_LIST  = [];
const PER_PAGE = 40;

// ─── Data helpers ─────────────────────────────────────────────────────────────
function allSkins() {
  return (window.API && window.API.state.allSkins) || [];
}

function weaponBaseName(skinName) {
  return skinName.replace(/^★\s*/, '').trim();
}

function skinsForWeapon(weaponName) {
  const wl = weaponName.toLowerCase();
  return allSkins().filter(s => weaponBaseName(s.name).toLowerCase() === wl);
}

function skinsForCat(catId) {
  return allSkins().filter(s => s.category === catId);
}

function weaponImg(weaponName) {
  return skinsForWeapon(weaponName)[0]?.image || '';
}

function sortedSkins(list) {
  if (SKIN_SORT === 'date') {
    return [...list].sort((a, b) => {
      const da = a.releaseDate || '', db = b.releaseDate || '';
      if (da && db) return db.localeCompare(da);
      if (da) return -1;
      if (db) return 1;
      return (a.name + a.variant).localeCompare(b.name + b.variant);
    });
  }
  if (SKIN_SORT === 'price') {
    return [...list].sort((a, b) => {
      if (a.priceNum > 0 && b.priceNum > 0) return a.priceNum - b.priceNum;
      if (a.priceNum > 0) return -1;
      if (b.priceNum > 0) return  1;
      return (a.name + a.variant).localeCompare(b.name + b.variant);
    });
  }
  if (SKIN_SORT === 'rarity') {
    return [...list].sort((a, b) => {
      const ra = RARITY_RANK[a.rarity] || 0, rb = RARITY_RANK[b.rarity] || 0;
      if (rb !== ra) return rb - ra;
      return (a.name + a.variant).localeCompare(b.name + b.variant);
    });
  }
  if (SKIN_SORT === 'price-desc') return [...list].sort((a, b) => b.priceNum - a.priceNum);
  return [...list].sort((a, b) => (a.name + a.variant).localeCompare(b.name + b.variant));
}

// ─── Navigation ───────────────────────────────────────────────────────────────
function showView(id) {
  document.querySelectorAll('.view').forEach(v => v.classList.remove('active'));
  document.getElementById(id).classList.add('active');
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function setViewOrbs(color) {
  const orbs = document.getElementById('viewOrbs');
  const o1   = document.getElementById('vOrb1');
  if (!orbs || !o1) return;
  if (!color) { orbs.classList.remove('active'); return; }
  o1.style.backgroundColor = color;
  o1.style.opacity = '0.13';
  orbs.classList.add('active');
}

function goHome() {
  VIEW = 'home'; VIEW_CAT_ID = null; VIEW_WEAPON = null; VIEW_SEARCH = ''; VIEW_FILTER_FN = null;
  document.title = 'CSSkins — CS2 Skin Price Comparator';
  setViewOrbs(null);
  showView('view-home');
  refreshCatCards();
}

function goCategory(catId) {
  const cat = CAT_BY_ID[catId];
  if (!cat) return;
  if (!cat.accent) cat.accent = '#7b8698';
  VIEW = 'cat'; VIEW_CAT_ID = catId; VIEW_WEAPON = null; VIEW_SEARCH = ''; VIEW_FILTER_FN = null;
  document.title = cat.label + ' — CSSkins';
  setViewOrbs(cat.accent);
  showView('view-cat');

  document.getElementById('breadcrumb-cat').innerHTML =
    `<span class="breadcrumb-link" onclick="goHome()">Home</span>
     <span class="breadcrumb-sep">›</span>
     <span class="breadcrumb-current" style="color:${cat.accent}">${cat.label}</span>`;

  const catCount = skinsForCat(catId).length;
  document.getElementById('cat-title').textContent = cat.label;
  document.getElementById('cat-sub').textContent =
    cat.weapons.length + ' weapon types' + (catCount ? ' · ' + catCount.toLocaleString() + ' skins' : '');
  document.getElementById('cat-title').style.color = cat.accent;

  renderWeaponGrid(catId);
}

function goWeapon(weaponName, catId) {
  const skins = skinsForWeapon(weaponName);
  VIEW = 'skins'; VIEW_CAT_ID = catId || VIEW_CAT_ID; VIEW_WEAPON = weaponName; VIEW_SEARCH = ''; VIEW_FILTER_FN = null;
  document.title = weaponName + ' Skins — CSSkins';
  SKIN_PAGE = 1;
  SKIN_SORT = 'date';
  SKIN_LIST = sortedSkins(skins);
  const _wCat = CAT_BY_ID[catId || VIEW_CAT_ID];
  setViewOrbs(_wCat ? _wCat.accent : null);
  showView('view-skins');

  const cat = CAT_BY_ID[VIEW_CAT_ID];
  const bc  = document.getElementById('breadcrumb-skins');
  if (cat) {
    bc.innerHTML =
      `<span class="breadcrumb-link" onclick="goHome()">Home</span>
       <span class="breadcrumb-sep">›</span>
       <span class="breadcrumb-link" onclick="goCategory('${cat.id}')" style="color:${cat.accent}">${cat.label}</span>
       <span class="breadcrumb-sep">›</span>
       <span class="breadcrumb-current">${weaponName}</span>`;
  } else {
    bc.innerHTML =
      `<span class="breadcrumb-link" onclick="goHome()">Home</span>
       <span class="breadcrumb-sep">›</span>
       <span class="breadcrumb-current">${weaponName}</span>`;
  }

  document.getElementById('skins-title').textContent = weaponName;
  syncSortBtns();
  updateSkinsHeader();
  renderSkinPage();
}

function goSearch(q) {
  if (!q.trim()) { goHome(); return; }
  const skins = allSkins().filter(s =>
    (s.name + ' ' + s.variant).toLowerCase().includes(q.toLowerCase())
  );
  VIEW = 'skins'; VIEW_CAT_ID = null; VIEW_WEAPON = null; VIEW_SEARCH = q; VIEW_FILTER_FN = null;
  SKIN_PAGE = 1;
  SKIN_LIST = sortedSkins(skins);
  document.title = '"' + q + '" — CSSkins';
  setViewOrbs(null);
  showView('view-skins');

  document.getElementById('breadcrumb-skins').innerHTML =
    `<span class="breadcrumb-link" onclick="goHome()">Home</span>
     <span class="breadcrumb-sep">›</span>
     <span class="breadcrumb-current">Search: "${escHtml(q)}"</span>`;
  document.getElementById('skins-title').textContent = 'Search results';
  updateSkinsHeader();
  renderSkinPage();
}

function goFilterRarity(rarity) {
  const label = RARITY_LABELS[rarity] || rarity;
  VIEW_FILTER_FN = skins => skins.filter(s => s.rarity === rarity);
  VIEW = 'skins'; VIEW_CAT_ID = null; VIEW_WEAPON = null; VIEW_SEARCH = '';
  SKIN_PAGE = 1;
  SKIN_LIST = sortedSkins(VIEW_FILTER_FN(allSkins()));
  document.title = label + ' Skins — CSSkins';
  setViewOrbs(null);
  showView('view-skins');
  document.getElementById('breadcrumb-skins').innerHTML =
    `<span class="breadcrumb-link" onclick="goHome()">Home</span>
     <span class="breadcrumb-sep">›</span>
     <span class="breadcrumb-current">Rarity: ${escHtml(label)}</span>`;
  document.getElementById('skins-title').textContent = label + ' Skins';
  updateSkinsHeader();
  renderSkinPage();
}

function goFilterCollection(collection) {
  VIEW_FILTER_FN = skins => skins.filter(s => s.collection === collection);
  VIEW = 'skins'; VIEW_CAT_ID = null; VIEW_WEAPON = null; VIEW_SEARCH = '';
  SKIN_PAGE = 1;
  SKIN_SORT = 'rarity';
  SKIN_LIST = sortedSkins(VIEW_FILTER_FN(allSkins()));
  document.title = escHtml(collection) + ' — CSSkins';
  setViewOrbs(null);
  showView('view-skins');
  document.getElementById('breadcrumb-skins').innerHTML =
    `<span class="breadcrumb-link" onclick="goHome()">Home</span>
     <span class="breadcrumb-sep">›</span>
     <span class="breadcrumb-current">${escHtml(collection)}</span>`;
  document.getElementById('skins-title').textContent = collection;
  syncSortBtns();
  updateSkinsHeader();
  renderSkinPage();
}

function searchByCollection(name) {
  const nl = name.toLowerCase();
  const skins = allSkins().filter(s =>
    s.collection && s.collection.toLowerCase().includes(nl)
  );
  VIEW = 'skins'; VIEW_CAT_ID = null; VIEW_WEAPON = null; VIEW_SEARCH = '';
  SKIN_PAGE = 1; SKIN_SORT = 'rarity'; SKIN_LIST = sortedSkins(skins);
  document.title = name + ' — CSSkins';
  setViewOrbs(null);
  showView('view-skins');
  document.getElementById('breadcrumb-skins').innerHTML =
    `<span class="breadcrumb-link" onclick="goHome()">Home</span>
     <span class="breadcrumb-sep">›</span>
     <span class="breadcrumb-current">${escHtml(name)}</span>`;
  document.getElementById('skins-title').textContent = name;
  document.getElementById('skins-sub').textContent = skins.length + ' skins';
  syncSortBtns();
  updateSkinsHeader();
  renderSkinPage();
}

// ─── Skin list interactions ───────────────────────────────────────────────────
function syncSortBtns() {
  document.querySelectorAll('#sortOptions .sort-btn').forEach(b => {
    b.classList.toggle('active', b.getAttribute('onclick')?.includes(`'${SKIN_SORT}'`));
  });
}

function setSkinSort(btn, sort) {
  SKIN_SORT = sort;
  SKIN_PAGE = 1;
  document.querySelectorAll('#sortOptions .sort-btn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  if (VIEW_WEAPON)         SKIN_LIST = sortedSkins(skinsForWeapon(VIEW_WEAPON));
  else if (VIEW_SEARCH)    SKIN_LIST = sortedSkins(allSkins().filter(s => (s.name + ' ' + s.variant).toLowerCase().includes(VIEW_SEARCH.toLowerCase())));
  else if (VIEW_FILTER_FN) SKIN_LIST = sortedSkins(VIEW_FILTER_FN(allSkins()));
  else                     SKIN_LIST = sortedSkins(allSkins());
  renderSkinPage();
}

function skinGoPage(p) {
  const max = Math.ceil(SKIN_LIST.length / PER_PAGE);
  if (p < 1 || p > max) return;
  SKIN_PAGE = p;
  const url = new URL(location.href);
  if (p === 1) url.searchParams.delete('page');
  else url.searchParams.set('page', p);
  history.replaceState(null, '', url.toString());
  renderSkinPage();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

var _searchTimer = null;
function onHeroSearch(q) {
  clearTimeout(_searchTimer);
  _searchTimer = setTimeout(() => { if (q.trim()) goSearch(q); }, 320);
}

function focusSearch() {
  goHome();
  setTimeout(() => document.getElementById('heroSearch')?.focus(), 100);
}

function openSkin(id) {
  const skin = allSkins().find(s => s.id === id);
  try { if (skin) sessionStorage.setItem('csskins_detail', JSON.stringify(skin)); } catch(e) {}
  window.location = 'skin.html?skin=' + encodeURIComponent(id);
}

// ─── window.renderSkins callback (called by fetch-skins + fetch-prices) ───────
window.renderSkins = function(slice) {
  populateNavImages();
  populateCollectionsNav();

  const n  = allSkins().length;
  const sc = document.getElementById('statusSkinCount');
  if (sc && n) sc.textContent = n.toLocaleString();
  const hs = document.getElementById('heroStatSkins');
  if (hs && n) hs.textContent = n.toLocaleString();

  if (window._pendingFilter && n > 0) {
    const f = window._pendingFilter;
    window._pendingFilter = null;
    if      (f.kind === 'search')     goSearch(f.value);
    else if (f.kind === 'rarity')     goFilterRarity(f.value);
    else if (f.kind === 'collection') goFilterCollection(f.value);
    else if (f.kind === 'weapon')     goWeapon(f.value, f.catId || null);
    else if (f.kind === 'type')       goCategory(f.value);
    return;
  }

  if (VIEW === 'home')  { refreshCatCards(); renderTrending(); return; }
  if (VIEW === 'cat')   { refreshWeaponCards(); return; }
  if (VIEW === 'skins') {
    if (VIEW_WEAPON)         SKIN_LIST = sortedSkins(skinsForWeapon(VIEW_WEAPON));
    else if (VIEW_SEARCH)    SKIN_LIST = sortedSkins(allSkins().filter(s =>
      (s.name + ' ' + s.variant).toLowerCase().includes(VIEW_SEARCH.toLowerCase())
    ));
    else if (VIEW_FILTER_FN) SKIN_LIST = sortedSkins(VIEW_FILTER_FN(allSkins()));
    renderSkinPage();
  }
};

// ─── URL filter on load (from skin.html links) ────────────────────────────────
(function() {
  const p          = new URLSearchParams(location.search);
  const search     = p.get('search');
  const rarity     = p.get('rarity');
  const collection = p.get('collection');
  const catType    = p.get('type');
  const weapon     = p.get('weapon');
  const page       = parseInt(p.get('page') || '1', 10);
  if (page > 1) SKIN_PAGE = page;
  if      (search)     window._pendingFilter = { kind: 'search',     value: search,     page };
  else if (rarity)     window._pendingFilter = { kind: 'rarity',     value: rarity,     page };
  else if (collection) window._pendingFilter = { kind: 'collection', value: collection, page };
  else if (weapon)     window._pendingFilter = { kind: 'weapon',     value: weapon,     catId: catType, page };
  else if (catType)    window._pendingFilter = { kind: 'type',       value: catType,    page };
})();

// ─── CORS error sanitizer ─────────────────────────────────────────────────────
(function() {
  const sanitize = text => {
    if (!text) return text;
    if (/cors/i.test(text))              return 'Checking prices…';
    if (/error|fail|blocked/i.test(text)) return 'Unavailable';
    return text;
  };
  ['pill-csfloat', 'pill-whitemarket'].forEach(id => {
    const el = document.getElementById(id);
    if (!el) return;
    new MutationObserver(() => {
      const txt = el.querySelector('.pill-text');
      if (txt) {
        const cleaned = sanitize(txt.textContent);
        if (cleaned !== txt.textContent) txt.textContent = cleaned;
      }
    }).observe(el, { childList: true, subtree: true, characterData: true });
  });
})();

// ─── Init ─────────────────────────────────────────────────────────────────────
buildNav();
renderCatGrid();

async function apiStart() {
  await fetchByMykel();
  await Promise.allSettled([
    fetchCSFloatPrices(),
    fetchWhiteMarketPrices(),
  ]);
}

apiStart();
setInterval(() => { if (!_apiState.loading) fetchCSFloatPrices(); }, REFRESH_MS);
