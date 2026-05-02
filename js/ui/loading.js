// Loading bar, pill status indicators, sidebar stats

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

function setPillStatus(pillId, status, label) {
  const el = document.getElementById(pillId);
  if (!el) return;
  const dot  = el.querySelector('.dot');
  const text = el.querySelector('.pill-text');
  const cls  = status === 'ok' ? 'dot-green' : status === 'loading' ? 'dot-yellow' : 'dot-red';
  if (dot)  dot.className = 'dot ' + cls;
  if (text) text.textContent = label;
}

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
    FN: skins.filter(s => s.wear === 'FN').length,
    MW: skins.filter(s => s.wear === 'MW').length,
    FT: skins.filter(s => s.wear === 'FT').length,
    WW: skins.filter(s => s.wear === 'WW').length,
    BS: skins.filter(s => s.wear === 'BS').length,
  };
  document.querySelectorAll('[data-cat]').forEach(el => {
    const cnt = el.querySelector('.sidebar-count');
    if (cnt && counts[el.dataset.cat] !== undefined)
      cnt.textContent = counts[el.dataset.cat].toLocaleString();
  });
}
