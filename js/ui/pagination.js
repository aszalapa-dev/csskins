// Pagination helpers used by the API state machine (index page)

function renderApiPagination(total) {
  const el = document.querySelector('.pagination');
  if (!el) return;
  const totalPages = Math.ceil(total / PAGE_SIZE);
  const page = window.API ? window.API.state.page : 1;
  if (totalPages <= 1) { el.innerHTML = ''; return; }

  let html = apiPBtn('‹', page - 1, page === 1);
  for (const p of pageRange(page, totalPages)) {
    html += p === '…'
      ? '<button class="page-btn" style="cursor:default;pointer-events:none">…</button>'
      : apiPBtn(p, p, p === page);
  }
  html += apiPBtn('›', page + 1, page === totalPages);
  el.innerHTML = html;
}

function apiPBtn(label, target, disabled) {
  const page   = window.API ? window.API.state.page : 1;
  const active = typeof target === 'number' && target === page ? ' active' : '';
  const dis    = disabled ? ' disabled' : '';
  const click  = disabled ? '' : ` onclick="window.API.goToPage(${target})"`;
  return `<button class="page-btn${active}"${dis}${click}>${label}</button>`;
}
