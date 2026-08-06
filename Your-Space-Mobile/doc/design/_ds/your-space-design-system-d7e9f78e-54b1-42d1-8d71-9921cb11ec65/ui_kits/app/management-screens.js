/*
  management-screens.js — Your Space design system

  Shared list+CRUD renderer for the three "entity management" screens:
  Subgroups (scoped to a Group), Cities (scoped to a Governorate) and
  Neighborhoods (scoped to a City). The task calls these "clear siblings
  of the same list+CRUD pattern" — so rather than hand-copy the markup
  three times, this file implements the pattern once and each HTML file
  supplies its own small config object (labels, icon, seed data).

  Every visual piece reuses existing tokens/classes from new-screens.css,
  which in turn are copied 1:1 from the existing component source
  (Card, ListTile, Input, Button, IconButton, EmptyState, Dialog, the
  bottom-sheet pattern already used for Create/Edit group in the
  existing app kit mockups).
*/

function initManagementScreen(config) {
  const {
    entitySingular,      // e.g. 'Subgroup'
    entityPlural,        // e.g. 'Subgroups'
    parentLabel,         // e.g. 'Group'
    parentName,          // e.g. 'Family'
    parentIcon,           // Material Symbols name
    itemIcon,             // Material Symbols name for each row's leading icon
    items,                // [{ id, name, caption }]
    emptyTitle,
    emptyBody,
    namePlaceholder,
    searchPlaceholder
  } = config;

  let list = items.slice();
  let nextId = Math.max(0, ...list.map(i => i.id)) + 1;
  let query = '';
  let editingId = null;
  let deletingId = null;

  document.getElementById('appbarTitle').textContent = entityPlural;
  document.getElementById('contextStrip').innerHTML =
    '<span class="msr">' + parentIcon + '</span> ' + parentLabel + ' <strong>' + parentName + '</strong>';
  document.getElementById('searchInput').setAttribute('placeholder', searchPlaceholder);
  document.getElementById('sheetTitle').textContent = 'New ' + entitySingular.toLowerCase();

  const listCard = document.getElementById('listCard');
  const emptyStateEl = document.getElementById('emptyState');
  const emptyStateTitle = document.getElementById('emptyStateTitle');
  const emptyStateBody = document.getElementById('emptyStateBody');
  emptyStateTitle.textContent = emptyTitle;
  emptyStateBody.textContent = emptyBody;
  document.getElementById('emptyAddBtn').textContent = 'Add ' + entitySingular.toLowerCase();

  function render() {
    const filtered = list.filter(i => i.name.toLowerCase().includes(query.toLowerCase()));
    if (!list.length) {
      listCard.hidden = true;
      emptyStateEl.hidden = false;
      return;
    }
    emptyStateEl.hidden = true;
    listCard.hidden = false;
    listCard.innerHTML = '';
    if (!filtered.length) {
      listCard.innerHTML = '<div style="padding:24px 16px;text-align:center;font:var(--text-body-md);color:var(--text-hint)">Nothing matches &quot;' + query + '&quot;</div>';
      return;
    }
    filtered.forEach((item, idx) => {
      const row = document.createElement('div');
      row.innerHTML =
        '<div class="list-tile">' +
        '<span class="list-tile-icon"><span class="msr">' + itemIcon + '</span></span>' +
        '<div class="list-tile-body"><div class="list-tile-title">' + item.name + '</div>' +
        (item.caption ? '<div class="list-tile-subtitle">' + item.caption + '</div>' : '') + '</div>' +
        '<span class="list-tile-trailing">' +
        '<button type="button" class="icon-btn sz-36" data-edit="' + item.id + '"><span class="msr">edit</span></button>' +
        '<button type="button" class="icon-btn sz-36" data-delete="' + item.id + '"><span class="msr" style="color:var(--color-error)">delete</span></button>' +
        '</span></div>' +
        (idx < filtered.length - 1 ? '<div class="list-divider"></div>' : '');
      listCard.appendChild(row);
    });
  }

  document.getElementById('searchInput').addEventListener('input', e => { query = e.target.value; render(); });

  // ---- create / edit sheet ----
  const sheetScrim = document.getElementById('sheetScrim');
  const sheet = document.getElementById('sheet');
  const sheetTitle = document.getElementById('sheetTitle');
  const nameInput = document.getElementById('nameInput');
  const nameHint = document.getElementById('nameHint');
  const saveBtn = document.getElementById('sheetSaveBtn');

  function openSheet(id) {
    editingId = id || null;
    const existing = id ? list.find(i => i.id === id) : null;
    sheetTitle.textContent = existing ? ('Edit ' + entitySingular.toLowerCase()) : ('New ' + entitySingular.toLowerCase());
    nameInput.value = existing ? existing.name : '';
    nameInput.setAttribute('placeholder', namePlaceholder);
    nameHint.textContent = nameInput.value.length + ' / 200';
    saveBtn.textContent = existing ? 'Save changes' : ('Create ' + entitySingular.toLowerCase());
    sheetScrim.hidden = false; sheet.hidden = false;
    setTimeout(() => nameInput.focus(), 50);
  }
  function closeSheet() { sheetScrim.hidden = true; sheet.hidden = true; }

  nameInput.addEventListener('input', () => { nameHint.textContent = nameInput.value.length + ' / 200'; });
  document.getElementById('sheetCancelBtn').addEventListener('click', closeSheet);
  sheetScrim.addEventListener('click', closeSheet);
  document.getElementById('addFab').addEventListener('click', () => openSheet(null));
  document.getElementById('emptyAddBtn').addEventListener('click', () => openSheet(null));

  saveBtn.addEventListener('click', () => {
    const name = nameInput.value.trim();
    if (!name) return;
    if (editingId) {
      const existing = list.find(i => i.id === editingId);
      existing.name = name;
    } else {
      list.push({ id: nextId++, name, caption: '0 people' });
    }
    closeSheet();
    render();
  });

  listCard.addEventListener('click', e => {
    const editBtn = e.target.closest('[data-edit]');
    if (editBtn) { openSheet(Number(editBtn.dataset.edit)); return; }
    const delBtn = e.target.closest('[data-delete]');
    if (delBtn) { openDeleteDialog(Number(delBtn.dataset.delete)); }
  });

  // ---- delete dialog ----
  const dialogScrim = document.getElementById('dialogScrim');
  const dialogBody = document.getElementById('dialogBody');
  function openDeleteDialog(id) {
    deletingId = id;
    const item = list.find(i => i.id === id);
    dialogBody.textContent = 'This removes "' + item.name + '" — it can\'t be undone.';
    dialogScrim.hidden = false;
  }
  document.getElementById('dialogCancelBtn').addEventListener('click', () => { dialogScrim.hidden = true; });
  document.getElementById('dialogConfirmBtn').addEventListener('click', () => {
    list = list.filter(i => i.id !== deletingId);
    dialogScrim.hidden = true;
    render();
  });

  render();
}
