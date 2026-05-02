// Responsibility: fetch live prices from CSFloat and white.market, merge into skin objects

function setPriceStatus(status, count) {
  const msgs = {
    'loading':    ['loading', 'CSFloat — chargement…'],
    'ok':         ['ok',      `CSFloat — ${count} prix`],
    'error':      ['error',   'CSFloat — erreur'],
    'cors-error': ['error',   'CSFloat — erreur proxy'],
  };
  const [s, label] = msgs[status] || ['loading', 'CSFloat'];
  setPillStatus('pill-csfloat', s, label);
}

async function fetchCSFloatPrices() {
  setPriceStatus('loading');
  const state = window.API.state;

  try {
    const priceMap = {};
    let cursor     = '';
    let pagesLoaded = 0;

    for (let p = 0; p < CSFLOAT_PAGES; p++) {
      const url = CSFLOAT_BASE + (cursor ? '&cursor=' + encodeURIComponent(cursor) : '');
      let data;
      try {
        const r = await fetch(url);
        if (r.status === 429) { console.warn('[CSSkins] CSFloat rate-limit — arrêt pagination'); break; }
        if (!r.ok) throw new Error('CSFloat ' + r.status);
        data = await r.json();
      } catch (e) {
        if (pagesLoaded === 0) {
          console.error('[CSSkins] CSFloat page 0 échouée :', e.message);
          setPriceStatus('cors-error');
          return;
        }
        break;
      }

      const listings = data.data || [];
      for (const listing of listings) {
        const item = listing.item;
        if (!item || item.type !== 'skin') continue;
        const itemName = (item.item_name || '').trim();
        if (!itemName) continue;
        const priceEur = (listing.price / 100) * USD_TO_EUR;
        if (priceEur <= 0) continue;
        const mapKey   = itemName.toLowerCase();
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

    let matched = 0;
    for (const skin of state.allSkins) {
      const mapKey = (skin.variant !== 'Vanilla'
        ? skin.name + ' | ' + skin.variant
        : skin.name
      ).toLowerCase();
      const entry = priceMap[mapKey];
      if (entry) {
        skin.priceNum   = entry.priceEur;
        skin.csfloatUrl = `https://csfloat.com/item/${entry.listingId}`;
        skin.prices     = [{ site:'CSFloat', price:entry.priceStr, priceNum:entry.priceEur, best:true, url:skin.csfloatUrl, float:entry.float, wearName:entry.wearName }];
        if (entry.wearName && WEAR_FULL[entry.wearName]) skin.wear = WEAR_FULL[entry.wearName];
        if (entry.float != null) skin.float = parseFloat(entry.float).toFixed(4);
        matched++;
      }
    }

    state.pricesLoaded = true;
    console.log(`[CSSkins] Phase 2 : ${pagesLoaded} pages CSFloat → ${matched} skins avec prix`);
    setPriceStatus('ok', matched);
    renderApiPage();

  } catch (err) {
    console.error('[CSSkins] CSFloat :', err);
    setPriceStatus('error');
  }
}

async function fetchWhiteMarketPrices() {
  setPillStatus('pill-whitemarket', 'loading', 'white.market — chargement…');
  const state = window.API.state;
  try {
    const r = await fetch(WHITE_MARKET_URL);
    if (!r.ok) throw new Error('white.market ' + r.status);
    const items = await r.json();

    const WEAR_STRIP = / \((Factory New|Minimal Wear|Field-Tested|Well-Worn|Battle-Scarred)\)$/;
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
      const baseName = noWear.replace(ST_RE, ' ').replace(SV_RE, ' ')
                             .replace(/\s{2,}/g, ' ').trim().toLowerCase();
      if (!baseName) continue;
      const priceUsd = parseFloat(item.price || '0');
      if (priceUsd <= 0) continue;
      const priceEur = priceUsd * USD_TO_EUR;
      if (!priceMap[baseName]) priceMap[baseName] = { wears:{}, stWears:{}, svWears:{} };
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
      const allVals = [...Object.values(entry.wears), ...Object.values(entry.stWears), ...Object.values(entry.svWears)];
      if (!allVals.length) continue;
      const cheapest = allVals.reduce((a, b) => a.priceEur < b.priceEur ? a : b);
      skin.priceNum = cheapest.priceEur;
      skin.prices   = [{ site:'white.market', price:cheapest.priceStr, priceNum:cheapest.priceEur, best:true, url:cheapest.url }];
      matched++;
    }

    console.log(`[CSSkins] white.market : ${items.length} items → ${matched} skins mis à jour`);
    setPillStatus('pill-whitemarket', 'ok', `white.market — ${matched} prix`);
    renderApiPage();

  } catch (err) {
    const isCors = err instanceof TypeError && err.message.includes('fetch');
    const msg = isCors ? 'white.market — CORS bloqué' : 'white.market — erreur';
    console.warn('[CSSkins]', msg, err.message);
    setPillStatus('pill-whitemarket', 'error', msg);
  }
}
