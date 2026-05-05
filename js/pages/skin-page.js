// Responsibility: skin detail page state + boot + user interactions

window._skin            = null;
window._currentCategory = 'normal';
window._is3d            = false;

let _z = false, _m = false;

function boot() {
  const params = new URLSearchParams(location.search);
  const id = params.get('skin');
  let skin = null;
  try {
    const raw = sessionStorage.getItem('csskins_detail');
    if (raw) {
      skin = JSON.parse(raw);
      if (skin && id && skin.id !== decodeURIComponent(id)) skin = null;
    }
  } catch(e) {}
  if (skin) { render(skin); return; }
  if (id) fetchFallback(decodeURIComponent(id)); else showNotFound();
}

async function fetchFallback(id) {
  const readable = id.replace(/-/g, ' ');
  try {
    const r = await fetch('https://api.dmarket.com/exchange/v1/market/items?gameId=a8db&currency=USD&limit=30&title=' + encodeURIComponent(readable));
    const data = await r.json();
    const TYPES = new Set(['pistol','rifle','smg','sniper rifle','knife','gloves','shotgun','machinegun']);
    const items = (data.objects || []).filter(i => TYPES.has(i.extra?.itemType));
    if (!items.length) { showNotFound(); return; }
    items.sort((a,b) => parseInt(a.price?.USD||0) - parseInt(b.price?.USD||0));
    const skin = dmToSkin(items[0]);
    if (!skin) { showNotFound(); return; }
    render(skin);
  } catch(e) { showNotFound(); }
}

function dmToSkin(item) {
  const WM = { 'Factory New':'FN','Minimal Wear':'MW','Field-Tested':'FT','Well-Worn':'WW','Battle-Scarred':'BS' };
  const title = item.title || '';
  const isST = /StatTrak™/i.test(title);
  const clean = title.replace(/StatTrak™\s*/i,'').replace(/Souvenir\s*/i,'').trim();
  const m = clean.match(/\(([^)]+)\)$/);
  if (!m || !WM[m[1]]) return null;
  const wear = WM[m[1]];
  const base = clean.slice(0, -(m[0].length)).trim();
  const pipe = base.indexOf(' | ');
  if (pipe === -1) return null;
  const weapon  = base.slice(0, pipe).trim();
  const variant = base.slice(pipe + 3);
  const priceEur = (parseInt(item.price?.USD || '0') / 100) * 0.92;
  const hex = (item.extra?.nameColor || '').toLowerCase();
  const RM = { 'eb4b4b':'covert','e4ae39':'covert','d32ce6':'classified','8847ff':'classified','4b69ff':'restricted' };
  return {
    id: title.toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/-{2,}/g,'-').replace(/^-|-$/g,''),
    name: isST ? 'StatTrak™ ' + weapon : weapon,
    variant, wear,
    float: item.extra?.floatValue != null ? parseFloat(item.extra.floatValue).toFixed(4) : null,
    minFloat: 0.00,
    maxFloat: 1.00,
    rarity: RM[hex] || 'milspec',
    category: guessCategory(weapon),
    image: item.image || '',
    collection: item.extra?.collection?.[0] || '',
    prices: [{ site:'DMarket', price: fmt(priceEur), priceNum: priceEur, url: 'https://dmarket.com/ingame-items/item-list/csgo-skins' }],
    priceNum: priceEur,
    dmarketUrl: 'https://dmarket.com/ingame-items/item-list/csgo-skins?userOfferId=' + (item.extra?.offerId || ''),
  };
}

function guessCategory(w) {
  if (/Knife|Karambit|Bayonet|Daggers|Stiletto|Ursus|Navaja|Talon|Paracord|Survival|Nomad|Skeleton|Falchion|Gut |Flip |Shadow/i.test(w)) return 'knife';
  if (/Gloves|Wraps/i.test(w)) return 'glove';
  if (/AWP|SSG 08|SCAR-20|G3SG1/.test(w)) return 'sniper';
  if (/AK-47|M4A[14]|FAMAS|Galil|AUG|SG 553|M249|Negev/.test(w)) return 'rifle';
  if (/Glock|USP|P250|Desert Eagle|Five-SeveN|Tec-9|CZ75|Berettas|P2000|R8/.test(w)) return 'pistol';
  if (/MP[579]|UMP|P90|PP-Bizon|MAC-10/.test(w)) return 'smg';
  return 'rifle';
}

function fmt(n) {
  if (!n || n <= 0) return '—';
  return n >= 1000 ? '€' + Math.round(n).toLocaleString('de-DE') : '€' + n.toFixed(2);
}

function showNotFound() {
  document.getElementById('root').innerHTML = `
    <div class="notfound">
      <h2>Skin not found</h2>
      <p>This skin couldn't be loaded.</p>
      <a class="back-link" href="index.html">← Back to all skins</a>
    </div>`;
}

// ─── Category switch ──────────────────────────────────────────────────────────
function setCategory(cat) {
  window._currentCategory = cat;
  document.querySelectorAll('.cat-btn').forEach(b =>
    b.classList.toggle('active', b.dataset.cat === cat)
  );
  // onFloatChange re-renders floatPriceRow, best-card, AND Active Offers
  const slider = document.getElementById('floatSlider');
  if (slider && window._skin) onFloatChange(window._skin, parseFloat(slider.value));
}

// ─── Inspect.skin slug ───────────────────────────────────────────────────────
function inspectSkinSlug(skin) {
  const weapon = (skin.weaponName || skin.name || '')
    .toLowerCase().replace(/[^a-z0-9]/g, '');
  const variant = (skin.variant || '')
    .toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
  return variant ? `${weapon}-${variant}` : weapon;
}

// ─── View tab switch (Wear / 3D View) ────────────────────────────────────────
function setViewTab(tab) {
  document.querySelectorAll('.view-tab').forEach(b =>
    b.classList.toggle('active', b.dataset.tab === tab)
  );

  const img     = document.getElementById('skinImg');
  const v3d     = document.getElementById('viewer3d');
  const frame   = document.getElementById('inspectFrame');
  const btns    = document.getElementById('imgBtns');
  const bar     = document.querySelector('.img-bar');

  if (tab === '3d') {
    // Reset Three.js viewer if active
    if (window._is3d) {
      window._is3d = false;
      if (v3d)  v3d.style.display  = 'none';
      const btn3d = document.getElementById('btn3d');
      if (btn3d) { btn3d.textContent = '⬡ 3D'; btn3d.classList.remove('active'); }
    }
    if (img)  img.style.display  = 'none';
    if (btns) btns.style.display = 'none';
    if (bar)  bar.style.display  = 'none';
    if (frame) {
      frame.style.display = 'flex';
      if (!frame.dataset.loaded && window._skin) {
        const slug = inspectSkinSlug(window._skin);
        const url  = 'https://inspect.skin/' + slug;
        frame.dataset.loaded = '1';
        frame.innerHTML = `
          <iframe src="${url}"
                  allowfullscreen
                  allow="accelerometer; gyroscope; pointer-lock; autoplay"
                  title="3D view — ${slug}">
          </iframe>
          <div class="inspect-fallback">
            <span>3D view not available</span>
            <a href="${url}" target="_blank" rel="noopener">Open inspect.skin ↗</a>
          </div>`;
        // Hide the fallback if the iframe loads successfully
        const iframe = frame.querySelector('iframe');
        if (iframe) {
          iframe.addEventListener('load', () => {
            const fb = frame.querySelector('.inspect-fallback');
            try {
              // Cross-origin check: if accessible, loaded fine
              void iframe.contentWindow.location.href;
              if (fb) fb.style.display = 'none';
            } catch(_) {
              // Blocked by X-Frame-Options or CORS — show fallback
              if (fb) fb.style.display = 'flex';
              iframe.style.display = 'none';
            }
          });
        }
      }
    }
  } else {
    // Wear tab
    if (img)   img.style.display   = '';
    if (btns)  btns.style.display  = '';
    if (bar)   bar.style.display   = '';
    if (frame) frame.style.display = 'none';
  }
}

// ─── Image controls ───────────────────────────────────────────────────────────
function toggleZoom()   { _z = !_z; applyT(); }
function toggleMirror() { _m = !_m; applyT(); }
function applyT() {
  const img = document.getElementById('skinImg');
  if (!img) return;
  img.classList.toggle('zoomed',   _z);
  img.classList.toggle('mirrored', _m);
}
function copyURL() {
  navigator.clipboard?.writeText(location.href)
    .then(() => {
      const b = event.target;
      const o = b.textContent;
      b.textContent = '✓ Copied';
      setTimeout(() => b.textContent = o, 1500);
    })
    .catch(() => {});
}

// ─── 3D Viewer ────────────────────────────────────────────────────────────────
function toggle3DView() {
  const viewer = document.getElementById('viewer3d');
  const img    = document.getElementById('skinImg');
  const btn    = document.getElementById('btn3d');
  if (!viewer || !img || !btn) return;
  window._is3d = !window._is3d;
  if (window._is3d) {
    img.style.display    = 'none';
    viewer.style.display = 'flex';
    btn.textContent      = '◉ 2D';
    btn.classList.add('active');
    initViewer3DOnce();
  } else {
    viewer.style.display = 'none';
    img.style.display    = '';
    btn.textContent      = '⬡ 3D';
    btn.classList.remove('active');
  }
}

function initViewer3DOnce() {
  if (window._viewer) {
    const stage = document.querySelector('.img-stage');
    if (stage) window._viewer.resize(stage.offsetWidth, stage.offsetHeight);
    return;
  }
  if (!window.CS2SkinViewer) { setTimeout(initViewer3DOnce, 80); return; }
  const canvas = document.getElementById('viewer3dCanvas');
  if (!canvas) return;
  const stage = canvas.closest('.img-stage');
  const w = stage ? stage.offsetWidth  : 600;
  const h = stage ? stage.offsetHeight : 310;
  window._viewer = new window.CS2SkinViewer(canvas, w, h);
  const slider = document.getElementById('floatSlider');
  if (slider) window._viewer.setFloat(parseFloat(slider.value));
  const seedSlider = document.getElementById('seedSlider');
  const seedValEl  = document.getElementById('seedVal');
  if (seedSlider) {
    seedSlider.addEventListener('input', () => {
      const v = parseInt(seedSlider.value);
      if (seedValEl) seedValEl.textContent = v;
      window._viewer?.setSeed(v);
    });
  }
  setupViewerDrop();
}

function setViewerFinish(v) {
  document.querySelectorAll('.vf-btn').forEach(b =>
    b.classList.toggle('active', parseInt(b.dataset.finish) === v)
  );
  window._viewer?.setFinish(v);
}

function setupViewerDrop() {
  const drop = document.getElementById('viewerDrop');
  if (!drop) return;
  ['dragover','dragenter'].forEach(ev =>
    drop.addEventListener(ev, e => { e.preventDefault(); drop.classList.add('drag-over'); })
  );
  drop.addEventListener('dragleave', () => drop.classList.remove('drag-over'));
  drop.addEventListener('drop', e => {
    e.preventDefault();
    drop.classList.remove('drag-over');
    window._viewer?.processFiles(e.dataTransfer.files);
  });
}

boot();
