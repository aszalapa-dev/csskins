// CSSkins — Catalogue ByMykel + prix CSFloat + white.market
//
// Phase 1 : ByMykel         → tous les skins, affichage immédiat (sans prix)
// Phase 2 : CSFloat+white.market en parallèle → mise à jour des cartes
//
// Clé CSFloat : window.CSFLOAT_KEY (définie dans config.js, gitignore)
// Règle       : tous les skins restent affichés même sans prix.

(function () {
  'use strict';

  const BYMYKEL_URL      = 'https://raw.githubusercontent.com/ByMykel/CSGO-API/main/public/api/en/skins.json';
  const CSFLOAT_BASE     = 'https://csfloat.com/api/v1/listings?limit=50&sort_by=lowest_price&type=buy_now';
  const WHITE_MARKET_URL = 'https://s3.white.market/export/v1/prices/730.json';

  const PAGE_SIZE      = 50;
  const REFRESH_MS     = 5 * 60 * 1000;
  const CSFLOAT_PAGES  = 20;   // 20 × 50 = 1 000 listings → ~400–600 skins distincts
  const USD_TO_EUR     = 0.92;

  const WEAR_FULL = {
    'Factory New':'FN', 'Minimal Wear':'MW', 'Field-Tested':'FT',
    'Well-Worn':'WW',   'Battle-Scarred':'BS',
  };

  // ─── State ─────────────────────────────────────────────────────────────────
  const state = {
    allSkins:     [],
    filtered:     [],
    page:         1,
    search:       '',
    category:     'all',
    sort:         'name',
    pricesLoaded: false,
    loading:      false,
  };
  window.API = { state, goToPage, search: doSearch, setCategory: doCategory, setSort: doSort };

  // ─── Helpers ───────────────────────────────────────────────────────────────

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
    return n >= 1000
      ? '€' + Math.round(n).toLocaleString('de-DE')
      : '€' + n.toFixed(2);
  }

  // ─── ByMykel → skin object ─────────────────────────────────────────────────

  function toSkin(item) {
    if (!item.image || !item.name) return null;

    const fullName = item.name;
    const pipe     = fullName.indexOf(' | ');
    const weapon   = pipe !== -1 ? fullName.slice(0, pipe).trim() : fullName;
    const variant  = pipe !== -1 ? fullName.slice(pipe + 3).trim() : 'Vanilla';

    const avail  = (item.wears || []).map(w => WEAR_FULL[w.name]).filter(Boolean);
    const wear   = avail.includes('FT') ? 'FT' : (avail[0] || 'FT');
    const rarity = rarityClass(item.rarity?.name);

    const id = fullName.toLowerCase()
      .replace(/[^a-z0-9★]+/g, '-')
      .replace(/-{2,}/g, '-')
      .replace(/^-|-$/g, '');

    return {
      id,
      name:       weapon,
      variant,
      wear,
      float:      item.min_float != null ? parseFloat(item.min_float).toFixed(4) : '—',
      minFloat:   item.min_float != null ? parseFloat(item.min_float) : 0.00,
      maxFloat:   item.max_float != null ? parseFloat(item.max_float) : 1.00,
      stattrak:     item.stattrak  === true,
      souvenir:     item.souvenir  === true,
      rarity,
      rarityName:   item.rarity?.name    || '',
      categoryName: item.category?.name  || '',
      weaponName:   item.weapon?.name    || weapon,
      finishName:   item.pattern?.name   || (pipe !== -1 ? fullName.slice(pipe + 3).trim() : ''),
      paintIndex:   item.paint_index     != null ? String(item.paint_index) : '',
      team:         item.team?.name      || '',
      legacyModel:  item.legacy_model    === true,
      category:     getCategory(weapon),
      collection:   item.collections?.[0]?.name || '',
      image:        item.image,
      priceNum:   0,
      prices:     [],
      csfloatUrl: '',
    };
  }

  // ─── Phase 1 : chargement ByMykel ─────────────────────────────────────────

  async function fetchByMykel() {
    state.loading = true;
    setLoadingBar(true);
    try {
      const r = await fetch(BYMYKEL_URL);
      if (!r.ok) throw new Error('ByMykel ' + r.status);
      const items = await r.json();

      const skins = items.map(toSkin).filter(Boolean);
      skins.sort((a, b) => (a.name + a.variant).localeCompare(b.name + b.variant));

      state.allSkins  = skins;
      window.SKINS_DB = skins;
      applyFilters();
      updateStats(skins);
      console.log(`[CSSkins] Phase 1 : ${skins.length} skins ByMykel`);
    } catch (err) {
      console.error('[CSSkins] ByMykel :', err);
    } finally {
      state.loading = false;
      setLoadingBar(false);
    }
  }

  // ─── Phase 2 : prix CSFloat (arrière-plan) ────────────────────────────────

  async function fetchCSFloatPrices() {
    const apiKey = window.CSFLOAT_KEY;
    if (!apiKey) {
      console.warn('[CSSkins] CSFLOAT_KEY introuvable — config.js chargé ?');
      setPriceStatus('no-key');
      return;
    }

    setPriceStatus('loading');

    try {
      // Construit le price map : item_name (minuscule) → entrée la moins chère
      const priceMap = {};
      let cursor = '';
      let pagesLoaded = 0;

      for (let p = 0; p < CSFLOAT_PAGES; p++) {
        const url = CSFLOAT_BASE + (cursor ? '&cursor=' + encodeURIComponent(cursor) : '');
        let data;
        try {
          const r = await fetch(url, {
            headers: { 'Authorization': apiKey },
          });
          if (r.status === 429) {
            console.warn('[CSSkins] CSFloat rate-limit — arrêt pagination');
            break;
          }
          if (!r.ok) throw new Error('CSFloat ' + r.status);
          data = await r.json();
        } catch (e) {
          // CORS ou réseau — on s'arrête proprement
          if (pagesLoaded === 0) {
            console.error('[CSSkins] CSFloat page 0 échouée :', e.message,
              '— vérifier CORS (clé valide ? domaine autorisé ?)');
            setPriceStatus('cors-error');
            return;
          }
          break;
        }

        const listings = data.data || [];
        for (const listing of listings) {
          const item = listing.item;
          // Garder uniquement les skins (pas stickers, agents, etc.)
          if (!item || item.type !== 'skin') continue;

          const itemName = (item.item_name || '').trim();  // "AK-47 | Redline" (sans usure)
          if (!itemName) continue;

          const priceEur = (listing.price / 100) * USD_TO_EUR;
          if (priceEur <= 0) continue;

          const mapKey = itemName.toLowerCase();
          const existing = priceMap[mapKey];
          if (!existing || priceEur < existing.priceEur) {
            priceMap[mapKey] = {
              priceEur,
              priceStr:   formatEur(priceEur),
              float:      item.float_value,
              wearName:   item.wear_name || '',
              listingId:  listing.id,
              marketHash: item.market_hash_name || '',
            };
          }
        }

        cursor = data.cursor || '';
        pagesLoaded++;
        if (!cursor) break;
      }

      // Applique les prix sur les skins déjà affichés
      let matched = 0;
      for (const skin of state.allSkins) {
        // Clé de correspondance : "ak-47 | redline" ou "★ karambit"
        const mapKey = (skin.variant !== 'Vanilla'
          ? skin.name + ' | ' + skin.variant
          : skin.name
        ).toLowerCase();

        const entry = priceMap[mapKey];
        if (entry) {
          skin.priceNum   = entry.priceEur;
          skin.csfloatUrl = `https://csfloat.com/item/${entry.listingId}`;
          skin.prices     = [{
            site:     'CSFloat',
            price:    entry.priceStr,
            priceNum: entry.priceEur,
            best:     true,
            url:      skin.csfloatUrl,
            float:    entry.float,
            wearName: entry.wearName,
          }];
          // Met à jour l'usure et le float avec les valeurs réelles du listing
          if (entry.wearName && WEAR_FULL[entry.wearName]) {
            skin.wear = WEAR_FULL[entry.wearName];
          }
          if (entry.float != null) {
            skin.float = parseFloat(entry.float).toFixed(4);
          }
          matched++;
        }
      }

      state.pricesLoaded = true;
      console.log(`[CSSkins] Phase 2 : ${pagesLoaded} pages CSFloat → ${matched} skins avec prix`);
      setPriceStatus('ok', matched);
      renderPage();

    } catch (err) {
      console.error('[CSSkins] CSFloat :', err);
      setPriceStatus('error');
    }
  }

  // ─── Barre de chargement ───────────────────────────────────────────────────

  function setLoadingBar(on) {
    let bar = document.getElementById('csskins-bar');
    if (!bar) {
      bar = document.createElement('div');
      bar.id = 'csskins-bar';
      bar.style.cssText = 'position:fixed;top:0;left:0;height:3px;background:var(--accent);'
                        + 'transition:width .5s ease,opacity .4s;z-index:9999;pointer-events:none;width:0;opacity:0';
      document.body.appendChild(bar);
    }
    if (on) {
      bar.style.opacity = '1'; bar.style.width = '80%';
    } else {
      bar.style.width = '100%';
      setTimeout(() => { bar.style.opacity = '0'; setTimeout(() => { bar.style.width = '0'; }, 400); }, 300);
    }
  }

  function setPriceStatus(status, count) {
    const msgs = {
      'loading':    ['loading', 'CSFloat — chargement…'],
      'ok':         ['ok',      `CSFloat — ${count} prix`],
      'error':      ['error',   'CSFloat — erreur'],
      'cors-error': ['error',   'CSFloat — CORS bloqué'],
      'no-key':     ['error',   'CSFloat — clé manquante'],
    };
    const [s, label] = msgs[status] || ['loading', 'CSFloat'];
    setPillStatus('pill-csfloat', s, label);
  }

  // ─── Filtres / tri / pagination ────────────────────────────────────────────

  function applyFilters() {
    let list = state.allSkins;

    if (state.search) {
      const q = state.search.toLowerCase();
      list = list.filter(s => (s.name + ' ' + s.variant).toLowerCase().includes(q));
    }

    const cat = state.category;
    if (cat !== 'all') {
      list = list.filter(s => s.rarity === cat || s.wear === cat || s.category === cat);
    }

    if (state.sort === 'name') {
      list = [...list].sort((a, b) => (a.name + a.variant).localeCompare(b.name + b.variant));
    } else if (state.sort === 'price') {
      list = [...list].sort((a, b) => {
        if (a.priceNum > 0 && b.priceNum > 0) return a.priceNum - b.priceNum;
        if (a.priceNum > 0) return -1;
        if (b.priceNum > 0) return  1;
        return (a.name + a.variant).localeCompare(b.name + b.variant);
      });
    } else if (state.sort === 'price-desc') {
      list = [...list].sort((a, b) => b.priceNum - a.priceNum);
    }

    state.filtered = list;
    state.page     = 1;
    renderPage();
  }

  function renderPage() {
    const { filtered, page } = state;
    const slice = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);
    if (typeof window.renderSkins === 'function') window.renderSkins(slice);
    const rc = document.getElementById('resultCount');
    if (rc) rc.textContent = filtered.length.toLocaleString();
    renderPagination(filtered.length);
  }

  function renderPagination(total) {
    const el = document.querySelector('.pagination');
    if (!el) return;
    const totalPages = Math.ceil(total / PAGE_SIZE);
    const { page } = state;
    if (totalPages <= 1) { el.innerHTML = ''; return; }

    let html = btn('‹', page - 1, page === 1);
    for (const p of pageRange(page, totalPages)) {
      html += p === '…'
        ? '<button class="page-btn" style="cursor:default;pointer-events:none">…</button>'
        : btn(p, p, p === page);
    }
    html += btn('›', page + 1, page === totalPages);
    el.innerHTML = html;
  }

  function btn(label, target, disabled) {
    const cls   = typeof target === 'number' && target === state.page ? ' active' : '';
    const dis   = disabled ? ' disabled' : '';
    const click = disabled ? '' : ` onclick="window.API.goToPage(${target})"`;
    return `<button class="page-btn${cls}"${dis}${click}>${label}</button>`;
  }

  function pageRange(cur, total) {
    if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1);
    if (cur <= 4)         return [1, 2, 3, 4, 5, '…', total];
    if (cur >= total - 3) return [1, '…', total - 4, total - 3, total - 2, total - 1, total];
    return [1, '…', cur - 1, cur, cur + 1, '…', total];
  }

  function goToPage(p) {
    const max = Math.ceil(state.filtered.length / PAGE_SIZE);
    if (p < 1 || p > max) return;
    state.page = p;
    renderPage();
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  function doSearch(q)   { state.search   = q; applyFilters(); }
  function doCategory(c) { state.category = c; applyFilters(); }
  function doSort(s)     { state.sort     = s; applyFilters(); }

  // ─── Statistiques sidebar ──────────────────────────────────────────────────

  function updateStats(skins) {
    const tracked = document.getElementById('statSkinsTracked');
    if (tracked) tracked.textContent = skins.length.toLocaleString() + '+';

    const counts = {
      all:        skins.length,
      rifle:      skins.filter(s => s.category === 'rifle').length,
      pistol:     skins.filter(s => s.category === 'pistol').length,
      knife:      skins.filter(s => s.category === 'knife').length,
      glove:      skins.filter(s => s.category === 'glove').length,
      smg:        skins.filter(s => s.category === 'smg').length,
      sniper:     skins.filter(s => s.category === 'sniper').length,
      covert:     skins.filter(s => s.rarity === 'covert').length,
      classified: skins.filter(s => s.rarity === 'classified').length,
      restricted: skins.filter(s => s.rarity === 'restricted').length,
      milspec:    skins.filter(s => s.rarity === 'milspec').length,
      FN:         skins.filter(s => s.wear === 'FN').length,
      MW:         skins.filter(s => s.wear === 'MW').length,
      FT:         skins.filter(s => s.wear === 'FT').length,
      WW:         skins.filter(s => s.wear === 'WW').length,
      BS:         skins.filter(s => s.wear === 'BS').length,
    };
    document.querySelectorAll('[data-cat]').forEach(el => {
      const cnt = el.querySelector('.sidebar-count');
      if (cnt && counts[el.dataset.cat] !== undefined)
        cnt.textContent = counts[el.dataset.cat].toLocaleString();
    });
  }

  // ─── Phase 2b : prix white.market (parallèle avec CSFloat) ──────────────────

  async function fetchWhiteMarketPrices() {
    setPillStatus('pill-whitemarket', 'loading', 'white.market — chargement…');
    try {
      const r = await fetch(WHITE_MARKET_URL);
      if (!r.ok) throw new Error('white.market ' + r.status);
      const items = await r.json();

      // market_hash_name formats:
      //   "AK-47 | Redline (Field-Tested)"
      //   "StatTrak™ AK-47 | Redline (Field-Tested)"
      //   "★ StatTrak™ Karambit | Doppler (Factory New)"   ← knives/gloves
      //   "Souvenir AK-47 | Redline (Field-Tested)"
      // Build: baseName → { wears:{FN:{…},…}, stWears:{…}, svWears:{…} }
      const WEAR_STRIP = / \((Factory New|Minimal Wear|Field-Tested|Well-Worn|Battle-Scarred)\)$/;
      // No ^ anchor — StatTrak/Souvenir can appear anywhere (e.g. after ★)
      const ST_RE = /\s*StatTrak™\s*/i;
      const SV_RE = /\s*Souvenir\s*/i;
      const priceMap = {};

      for (const item of items) {
        const mhn       = item.market_hash_name || '';
        const wearMatch = mhn.match(WEAR_STRIP);
        if (!wearMatch) continue;

        const wearCode = WEAR_FULL[wearMatch[1]] || 'FT';
        const noWear   = mhn.replace(WEAR_STRIP, '').trim();
        const isST     = ST_RE.test(noWear);
        const isSV     = !isST && SV_RE.test(noWear);
        // Strip StatTrak/Souvenir token and normalise spaces
        const baseName = noWear.replace(ST_RE, ' ').replace(SV_RE, ' ')
                               .replace(/\s{2,}/g, ' ').trim().toLowerCase();
        if (!baseName) continue;

        const priceUsd = parseFloat(item.price || '0');
        if (priceUsd <= 0) continue;
        const priceEur = priceUsd * USD_TO_EUR;

        if (!priceMap[baseName]) priceMap[baseName] = { wears: {}, stWears: {}, svWears: {} };
        const bucket = isST ? priceMap[baseName].stWears
                     : isSV ? priceMap[baseName].svWears
                     :        priceMap[baseName].wears;

        if (!bucket[wearCode] || priceEur < bucket[wearCode].priceEur) {
          bucket[wearCode] = {
            priceEur,
            priceStr: formatEur(priceEur),
            url:      item.market_product_link || 'https://white.market',
            float:    item.cheapest_float,
          };
        }
      }

      // Apply per-wear prices to skins
      let matched = 0;
      for (const skin of state.allSkins) {
        const mapKey = (skin.variant !== 'Vanilla'
          ? skin.name + ' | ' + skin.variant
          : skin.name
        ).toLowerCase();

        const entry = priceMap[mapKey];
        if (!entry) continue;

        skin.wearPrices   = entry.wears;
        skin.stWearPrices = entry.stWears;
        skin.svWearPrices = entry.svWears;

        // Cheapest across all variants for sorting + backward compat
        const allVals = [
          ...Object.values(entry.wears),
          ...Object.values(entry.stWears),
          ...Object.values(entry.svWears),
        ];
        if (!allVals.length) continue;
        const cheapest  = allVals.reduce((a, b) => a.priceEur < b.priceEur ? a : b);
        skin.priceNum   = cheapest.priceEur;
        skin.prices     = [{
          site:     'white.market',
          price:    cheapest.priceStr,
          priceNum: cheapest.priceEur,
          best:     true,
          url:      cheapest.url,
        }];
        matched++;
      }

      console.log(`[CSSkins] white.market : ${items.length} items → ${matched} skins mis à jour`);
      setPillStatus('pill-whitemarket', 'ok', `white.market — ${matched} prix`);
      renderPage();

    } catch (err) {
      const isCors = err instanceof TypeError && err.message.includes('fetch');
      const msg = isCors ? 'white.market — CORS bloqué' : 'white.market — erreur';
      console.warn('[CSSkins]', msg, err.message);
      setPillStatus('pill-whitemarket', 'error', msg);
    }
  }

  // ─── Utilitaire pill générique ─────────────────────────────────────────────

  function setPillStatus(pillId, status, label) {
    const el = document.getElementById(pillId);
    if (!el) return;
    const dot  = el.querySelector('.dot');
    const text = el.querySelector('.pill-text');
    const cls  = status === 'ok' ? 'dot-green' : status === 'loading' ? 'dot-yellow' : 'dot-red';
    if (dot)  dot.className = 'dot ' + cls;
    if (text) text.textContent = label;
  }

  // ─── Démarrage ─────────────────────────────────────────────────────────────

  async function boot() {
    await fetchByMykel();
    // CSFloat et white.market en parallèle — chacun re-render quand prêt
    await Promise.allSettled([
      fetchCSFloatPrices(),
      fetchWhiteMarketPrices(),
    ]);
  }

  boot();
  setInterval(() => { if (!state.loading) fetchCSFloatPrices(); }, REFRESH_MS);

})();
