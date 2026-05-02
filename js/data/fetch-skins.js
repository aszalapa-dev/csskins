// Responsibility: fetch ByMykel skin catalogue and map to internal skin objects

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
    name:         weapon,
    variant,
    wear,
    float:        item.min_float != null ? parseFloat(item.min_float).toFixed(4) : '—',
    minFloat:     item.min_float != null ? parseFloat(item.min_float) : 0.00,
    maxFloat:     item.max_float != null ? parseFloat(item.max_float) : 1.00,
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
    collection:    item.collections?.[0]?.name  || '',
    collectionId:  item.collections?.[0]?.id    || '',
    collectionImg: item.collections?.[0]?.image || '',
    crateId:       item.crates?.[0]?.id         || '',
    skinCrates:    (item.crates || []).map(c => ({ id: c.id||'', name: c.name||'', image: c.image||'' })),
    releaseDate:   null,
    image:        item.image,
    priceNum:     0,
    prices:       [],
    csfloatUrl:   '',
  };
}

async function fetchByMykel() {
  const state = window.API.state;
  state.loading = true;
  setLoadingBar(true);
  try {
    const [skinsRes, cratesRes] = await Promise.all([
      fetch(BYMYKEL_URL),
      fetch(BYMYKEL_CRATES_URL),
    ]);
    if (!skinsRes.ok) throw new Error('ByMykel ' + skinsRes.status);

    const [items, cratesData] = await Promise.all([
      skinsRes.json(),
      cratesRes.ok ? cratesRes.json() : Promise.resolve([]),
    ]);

    const cratesMap = new Map();
    for (const c of (cratesData || [])) {
      if (c.id && c.first_sale_date) {
        cratesMap.set(c.id, c.first_sale_date.replace(/\//g, '-'));
      }
    }

    const skins = items.map(toSkin).filter(Boolean);
    for (const s of skins) {
      if (s.crateId) s.releaseDate = cratesMap.get(s.crateId) || null;
    }

    skins.sort((a, b) => {
      const da = a.releaseDate || '', db = b.releaseDate || '';
      if (da && db) return db.localeCompare(da);
      if (da) return -1;
      if (db) return 1;
      return (a.name + a.variant).localeCompare(b.name + b.variant);
    });

    state.allSkins  = skins;
    window.SKINS_DB = skins;
    applyApiFilters();
    updateStats(skins);
    console.log(`[CSSkins] Phase 1 : ${skins.length} skins ByMykel`);
  } catch (err) {
    console.error('[CSSkins] ByMykel :', err);
  } finally {
    state.loading = false;
    setLoadingBar(false);
  }
}
