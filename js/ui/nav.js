// Responsibility: build and populate the top navigation bar

function ddWeaponItem(w, catId) {
  const safe = w.replace(/\\/g,'\\\\').replace(/'/g,"\\'");
  return `<div class="dd-item" data-weapon="${escHtml(w)}" data-cat="${catId}"
               onclick="goWeapon('${safe}','${catId}')">
    <div class="dd-img-wrap"><div class="dd-img-ph"></div></div>
    <span class="dd-name">${escHtml(w)}</span>
  </div>`;
}

function buildNav() {
  const ul = document.getElementById('navLinks');

  const weaponHtml = NAV_CATS.map(cat => {
    const colsCls = cat.weapons.length > 8 ? 'cols-3' : 'cols-2';
    const gridCls = cat.id === 'sniper' ? 'cols-1' : colsCls;
    const items   = cat.weapons.map(w => ddWeaponItem(w, cat.id)).join('');
    return `
    <li>
      <div class="nav-item" onclick="goCategory('${cat.id}')">
        ${cat.label}<span class="nav-chevron">▾</span>
      </div>
      <div class="dropdown"><div class="dropdown-inner">
        <div class="dropdown-header">${cat.label}</div>
        <div class="dropdown-grid ${gridCls}">${items}</div>
        <div class="dropdown-footer">
          <div class="dd-view-all" onclick="event.stopPropagation();goCategory('${cat.id}')">
            View all ${cat.label} <span>→</span>
          </div>
        </div>
      </div></div>
    </li>`;
  }).join('');

  const casesHtml = CASES_NAV.map(c =>
    `<div class="dd-item-text" onclick="searchByCollection('${c.replace(/'/g,"\\'")}')">
      ${escHtml(c)}
    </div>`
  ).join('');

  ul.innerHTML = weaponHtml + `
  <li>
    <div class="nav-item">Cases<span class="nav-chevron">▾</span></div>
    <div class="dropdown"><div class="dropdown-inner">
      <div class="dropdown-header">Cases</div>
      <div class="dropdown-grid cols-1">${casesHtml}</div>
    </div></div>
  </li>
  <li>
    <div class="nav-item">Collections<span class="nav-chevron">▾</span></div>
    <div class="dropdown"><div class="dropdown-inner">
      <div class="dropdown-header">Collections</div>
      <div class="dropdown-grid cols-1" id="collectionsGrid">
        <div class="dd-item-text" style="color:var(--muted2);pointer-events:none">Loading…</div>
      </div>
    </div></div>
  </li>`;
}

function populateNavImages() {
  document.querySelectorAll('.dd-item[data-weapon]').forEach(el => {
    const wrap = el.querySelector('.dd-img-wrap');
    if (!wrap || wrap.querySelector('img')) return;
    const img = weaponImg(el.dataset.weapon);
    if (img) wrap.innerHTML = `<img class="dd-img" src="${img}" alt="${escHtml(el.dataset.weapon)}" loading="lazy">`;
  });
}

function populateCollectionsNav() {
  const grid = document.getElementById('collectionsGrid');
  if (!grid || grid.dataset.populated) return;
  const colMap = {};
  for (const s of allSkins()) {
    if (s.collection) colMap[s.collection] = (colMap[s.collection] || 0) + 1;
  }
  const cols = Object.entries(colMap).sort((a, b) => b[1] - a[1]).slice(0, 28).map(([name]) => name);
  if (!cols.length) return;
  grid.innerHTML = cols.map(c =>
    `<div class="dd-item-text" onclick="searchByCollection('${c.replace(/'/g,"\\'")}')">
      ${escHtml(c)}
    </div>`
  ).join('');
  grid.dataset.populated = '1';
}
