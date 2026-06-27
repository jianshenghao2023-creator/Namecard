(function () {
  const DB_NAME = 'namecard-query-local';
  const DB_VERSION = 1;
  const STORE_NAME = 'datasets';
  const DATA_KEY = 'current';
  const LOCAL_STORAGE_KEY = 'namecard-query-current';
  const HOSTED_DATA_URL = 'contacts-data.json';

  const state = {
    view: 'contacts',
    query: '',
    filter: 'all',
    loaded: false
  };

  let meta = {};
  let contacts = [];

  const textFields = [
    'record_id',
    'person_name',
    'chinese_name',
    'company',
    'company_normalized',
    'title',
    'industry_tags',
    'country',
    'city',
    'email_primary',
    'email_secondary',
    'mobile',
    'phone',
    'website',
    'address',
    'notes',
    'primary_category',
    'subcategory',
    'business_role'
  ];

  const els = {
    searchInput: document.getElementById('searchInput'),
    clearSearch: document.getElementById('clearSearch'),
    dataFileInput: document.getElementById('dataFileInput'),
    clearData: document.getElementById('clearData'),
    filterSelect: document.getElementById('filterSelect'),
    resultCount: document.getElementById('resultCount'),
    results: document.getElementById('results'),
    metaLine: document.getElementById('metaLine'),
    versionLine: document.getElementById('versionLine'),
    storageBadge: document.getElementById('storageBadge'),
    importPanel: document.getElementById('importPanel'),
    importTitle: document.getElementById('importTitle'),
    importHint: document.getElementById('importHint'),
    emptyTemplate: document.getElementById('emptyTemplate')
  };

  init();

  async function init() {
    bindEvents();
    exposeLocalApi();
    registerServiceWorker();
    setBusy(true);
    try {
      const stored = await loadStoredPayload();
      if (stored) {
        applyPayload(stored);
      } else {
        showNoData('正在同步在线数据');
      }
      await syncHostedData();
    } catch (error) {
      if (!state.loaded) {
        showNoData(`读取数据失败：${messageFrom(error)}`);
      } else {
        showImportError(`在线同步失败：${messageFrom(error)}`);
      }
    } finally {
      setBusy(false);
    }
  }

  function exposeLocalApi() {
    window.NAMECARD_APP = {
      importPayload: async (payload) => {
        if (!payload || !Array.isArray(payload.contacts)) {
          throw new Error('数据文件格式不正确');
        }
        payload.meta = Object.assign({}, payload.meta || {}, {
          importedAt: formatDate(new Date()),
          importedFileName: payload.meta && payload.meta.importedFileName || 'namecard_contacts_data.json'
        });
        await savePayload(payload);
        applyPayload(payload);
      }
    };
  }

  function bindEvents() {
    els.searchInput.addEventListener('input', () => {
      state.query = els.searchInput.value;
      render();
    });
    els.clearSearch.addEventListener('click', () => {
      els.searchInput.value = '';
      state.query = '';
      els.searchInput.focus();
      render();
    });
    els.filterSelect.addEventListener('change', () => {
      state.filter = els.filterSelect.value;
      render();
    });
    els.dataFileInput.addEventListener('change', importSelectedFile);
    els.clearData.addEventListener('click', clearLocalData);
    document.querySelectorAll('[data-view]').forEach((button) => {
      button.addEventListener('click', () => {
        state.view = button.dataset.view;
        document.querySelectorAll('[data-view]').forEach((item) => {
          const active = item === button;
          item.classList.toggle('active', active);
          item.setAttribute('aria-selected', String(active));
        });
        render();
      });
    });
  }

  async function importSelectedFile(event) {
    const file = event.target.files && event.target.files[0];
    event.target.value = '';
    if (!file) {
      return;
    }
    setBusy(true);
    try {
      const text = await file.text();
      const payload = parsePayload(text);
      payload.meta = Object.assign({}, payload.meta || {}, {
        importedAt: formatDate(new Date()),
        importedFileName: file.name
      });
      await savePayload(payload);
      applyPayload(payload);
      els.searchInput.focus();
    } catch (error) {
      showImportError(`导入失败：${messageFrom(error)}`);
    } finally {
      setBusy(false);
    }
  }

  async function syncHostedData() {
    let response;
    try {
      response = await fetch(`${HOSTED_DATA_URL}?t=${Date.now()}`, { cache: 'no-store' });
    } catch (error) {
      if (!state.loaded) {
        showNoData('未找到本地数据，联网后会自动同步');
      }
      return;
    }
    if (response.status === 404) {
      if (!state.loaded) {
        showNoData('网站未发布 contacts-data.json');
      }
      return;
    }
    if (!response.ok) {
      throw new Error(`在线数据读取失败 ${response.status}`);
    }
    const payload = parsePayload(await response.text());
    payload.meta = Object.assign({}, payload.meta || {}, {
      importedAt: formatDate(new Date()),
      importedFileName: HOSTED_DATA_URL,
      syncMode: 'online'
    });
    if (state.loaded && meta.dataVersion && payload.meta.dataVersion === meta.dataVersion) {
      els.storageBadge.textContent = '已同步';
      els.importHint.textContent = `在线数据已是最新 · 版本 ${payload.meta.dataVersion}`;
      return;
    }
    await savePayload(payload);
    applyPayload(payload);
  }

  async function clearLocalData() {
    if (!state.loaded) {
      return;
    }
    if (!window.confirm('清除这台手机里的本地名片数据？')) {
      return;
    }
    setBusy(true);
    try {
      await deletePayload();
      meta = {};
      contacts = [];
      state.query = '';
      state.filter = 'all';
      state.loaded = false;
      els.searchInput.value = '';
      els.filterSelect.value = 'all';
      showNoData();
    } catch (error) {
      showImportError(`清除失败：${messageFrom(error)}`);
    } finally {
      setBusy(false);
    }
  }

  function applyPayload(payload) {
    meta = payload.meta || {};
    contacts = normalizeContacts(payload.contacts || []);
    state.loaded = true;
    updateHeader();
    render();
  }

  function normalizeContacts(rawContacts) {
    return rawContacts.map((contact) => {
      const displayName = compact([contact.chinese_name, contact.person_name]).join(' / ') || '未命名联系人';
      const displayCompany = contact.company_normalized || contact.company || '未命名公司';
      const searchText = normalize(textFields.map((field) => contact[field] || '').join(' '));
      const isExpo = includesText(contact.notes, '2026希腊海事展') || includesText(contact.source_pdf, '希腊海事展');
      return Object.assign({}, contact, {
        displayName,
        displayCompany,
        searchText,
        isExpo
      });
    });
  }

  function updateHeader() {
    const contactCount = meta.contactCount || contacts.length;
    const companyCount = meta.companyCount || countCompanies(contacts);
    els.metaLine.textContent = `${contactCount} 位联系人，${companyCount} 家公司`;
    els.versionLine.textContent = meta.importedAt ? `本机导入 ${meta.importedAt}` : dataDateText();
    els.storageBadge.textContent = meta.syncMode === 'online' ? '已同步' : '已保存';
    els.storageBadge.classList.remove('offline');
    els.importPanel.classList.add('has-data');
    els.importTitle.textContent = meta.syncMode === 'online' ? '在线数据已同步' : '本地数据已导入';
    els.importHint.textContent = compact([
      meta.importedFileName || '',
      meta.sourceLastWriteTime ? `源数据 ${meta.sourceLastWriteTime}` : '',
      meta.dataVersion ? `版本 ${meta.dataVersion}` : ''
    ]).join(' · ') || '联网时会自动更新。';
    els.searchInput.disabled = false;
    els.clearSearch.disabled = false;
    els.filterSelect.disabled = false;
    els.clearData.disabled = false;
  }

  function showNoData(message) {
    els.metaLine.textContent = '未导入数据';
    els.versionLine.textContent = '';
    els.storageBadge.textContent = '空';
    els.storageBadge.classList.add('offline');
    els.importPanel.classList.remove('has-data');
    els.importTitle.textContent = '导入数据';
    els.importHint.textContent = message || '联网时自动同步，导入为备用';
    els.searchInput.disabled = true;
    els.clearSearch.disabled = true;
    els.filterSelect.disabled = true;
    els.clearData.disabled = true;
    els.resultCount.textContent = '0 条';
    els.results.className = 'results';
    els.results.innerHTML = `
      <div class="empty-state">
        <strong>还没有本地数据</strong>
        <span>等待在线同步</span>
      </div>
    `;
  }

  function showImportError(message) {
    els.importPanel.classList.add('error');
    els.importTitle.textContent = '需要重新导入';
    els.importHint.textContent = message;
    window.setTimeout(() => {
      els.importPanel.classList.remove('error');
      if (state.loaded) {
        updateHeader();
      }
    }, 4500);
  }

  function render() {
    if (!state.loaded) {
      showNoData();
      return;
    }
    const matched = contacts.filter(matchesContact);
    els.results.className = `results ${state.view === 'contacts' ? 'contact-results' : 'company-results'}`;
    if (state.view === 'contacts') {
      renderContacts(matched);
    } else {
      renderCompanies(matched);
    }
  }

  function renderContacts(items) {
    els.resultCount.textContent = `${items.length} 条联系人`;
    if (items.length === 0) {
      renderEmpty();
      return;
    }
    els.results.innerHTML = items.slice(0, 300).map(renderContactCard).join('');
  }

  function renderCompanies(items) {
    const companies = groupCompanies(items);
    els.resultCount.textContent = `${companies.length} 家公司`;
    if (companies.length === 0) {
      renderEmpty();
      return;
    }
    els.results.innerHTML = companies.slice(0, 180).map(renderCompanyCard).join('');
  }

  function renderEmpty() {
    els.results.innerHTML = '';
    els.results.appendChild(els.emptyTemplate.content.cloneNode(true));
  }

  function renderContactCard(contact) {
    const location = compact([contact.country, contact.city]).join(' / ');
    const category = compact([contact.primary_category_code, contact.primary_category]).join(' ');
    return `
      <article class="card">
        <div class="card-main">
          <div class="card-title">
            <div>
              <div class="name">${escapeHtml(contact.displayName)}</div>
              <div class="company">${escapeHtml(contact.displayCompany)}</div>
            </div>
          </div>
          ${line(contact.title, 'subline')}
          ${line(location, 'subline')}
          <div class="badges">
            ${badge(category, 'accent')}
            ${contact.isExpo ? badge('2026希腊海事展', 'warn') : ''}
          </div>
        </div>
        ${renderActions(contact)}
        <div class="details">
          ${detail('邮箱', compact([contact.email_primary, contact.email_secondary]).join(' / '))}
          ${detail('电话', compact([contact.mobile, contact.phone]).join(' / '))}
          ${detail('网站', contact.website)}
          ${detail('业务', compact([contact.subcategory, contact.business_role]).join(' / '))}
          ${detail('备注', contact.notes)}
        </div>
      </article>
    `;
  }

  function renderCompanyCard(company) {
    const categories = Array.from(company.categories).filter(Boolean).slice(0, 3).join(' / ');
    const countries = Array.from(company.countries).filter(Boolean).slice(0, 4).join(' / ');
    const people = company.people.slice(0, 12).map((person) => `
      <div class="person-row">
        <strong>${escapeHtml(person.displayName)}</strong>
        <span>${escapeHtml(compact([person.title, person.email_primary, person.mobile || person.phone]).join(' · '))}</span>
      </div>
    `).join('');
    return `
      <article class="card company-card">
        <div class="card-main">
          <div class="name">${escapeHtml(company.name)}</div>
          ${line(`${company.people.length} 位联系人`, 'subline')}
          ${line(categories, 'subline')}
          ${line(countries, 'subline')}
          <div class="badges">
            ${company.hasExpo ? badge('2026希腊海事展', 'warn') : ''}
          </div>
          <div class="people">${people}</div>
        </div>
      </article>
    `;
  }

  function renderActions(contact) {
    const phone = cleanPhone(contact.mobile || contact.phone);
    const email = contact.email_primary || contact.email_secondary;
    const website = normalizeWebsite(contact.website);
    const actions = [
      phone ? `<a class="action" href="tel:${escapeAttribute(phone)}">电话</a>` : '',
      email ? `<a class="action" href="mailto:${encodeURIComponent(email)}">邮件</a>` : '',
      website ? `<a class="action" href="${escapeAttribute(website)}" target="_blank" rel="noreferrer">网站</a>` : ''
    ].filter(Boolean).join('');
    return actions ? `<div class="actions">${actions}</div>` : '';
  }

  function matchesContact(contact) {
    if (!matchesFilter(contact)) {
      return false;
    }
    const query = normalize(state.query);
    if (!query) {
      return true;
    }
    return query.split(' ').every((token) => contact.searchText.includes(token));
  }

  function matchesFilter(contact) {
    switch (state.filter) {
      case 'expo':
        return contact.isExpo;
      case 'has-phone':
        return Boolean(cleanPhone(contact.mobile || contact.phone));
      case 'has-email':
        return Boolean(contact.email_primary || contact.email_secondary);
      default:
        return true;
    }
  }

  function groupCompanies(items) {
    const groups = new Map();
    items.forEach((contact) => {
      const name = contact.displayCompany;
      if (!groups.has(name)) {
        groups.set(name, {
          name,
          people: [],
          categories: new Set(),
          countries: new Set(),
          hasExpo: false
        });
      }
      const group = groups.get(name);
      group.people.push(contact);
      group.categories.add(contact.primary_category || contact.subcategory || '');
      group.countries.add(contact.country || '');
      group.hasExpo = group.hasExpo || contact.isExpo;
    });
    return Array.from(groups.values()).sort((a, b) => a.name.localeCompare(b.name, 'zh-Hans-CN'));
  }

  function parsePayload(text) {
    let source = String(text || '').trim();
    if (source.startsWith('window.NAMECARD_DATA')) {
      source = source.replace(/^window\.NAMECARD_DATA\s*=\s*/, '').replace(/;\s*$/, '');
    }
    const payload = JSON.parse(source);
    if (!payload || !Array.isArray(payload.contacts)) {
      throw new Error('数据文件格式不正确');
    }
    return payload;
  }

  async function loadStoredPayload() {
    if ('indexedDB' in window) {
      const stored = await withStore('readonly', (store) => store.get(DATA_KEY));
      return stored && stored.payload ? stored.payload : null;
    }
    const raw = window.localStorage.getItem(LOCAL_STORAGE_KEY);
    return raw ? JSON.parse(raw) : null;
  }

  async function savePayload(payload) {
    if ('indexedDB' in window) {
      await withStore('readwrite', (store) => store.put({ id: DATA_KEY, payload }));
      return;
    }
    window.localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(payload));
  }

  async function deletePayload() {
    if ('indexedDB' in window) {
      await withStore('readwrite', (store) => store.delete(DATA_KEY));
      return;
    }
    window.localStorage.removeItem(LOCAL_STORAGE_KEY);
  }

  function withStore(mode, action) {
    return openDb().then((db) => new Promise((resolve, reject) => {
      const transaction = db.transaction(STORE_NAME, mode);
      const store = transaction.objectStore(STORE_NAME);
      const request = action(store);
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
      transaction.oncomplete = () => db.close();
      transaction.onerror = () => {
        db.close();
        reject(transaction.error);
      };
    }));
  }

  function openDb() {
    return new Promise((resolve, reject) => {
      const request = window.indexedDB.open(DB_NAME, DB_VERSION);
      request.onupgradeneeded = () => {
        const db = request.result;
        if (!db.objectStoreNames.contains(STORE_NAME)) {
          db.createObjectStore(STORE_NAME, { keyPath: 'id' });
        }
      };
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  }

  function registerServiceWorker() {
    window.NAMECARD_PWA_STATUS = {
      supported: false,
      registered: false,
      error: ''
    };
    const canRegister = 'serviceWorker' in navigator &&
      (location.protocol === 'https:' || location.hostname === 'localhost' || location.hostname === '127.0.0.1');
    window.NAMECARD_PWA_STATUS.supported = canRegister;
    if (!canRegister) {
      return;
    }
    window.addEventListener('load', () => {
      navigator.serviceWorker.register('sw.js')
        .then(() => {
          window.NAMECARD_PWA_STATUS.registered = true;
        })
        .catch((error) => {
          window.NAMECARD_PWA_STATUS.error = messageFrom(error);
        });
    });
  }

  function setBusy(busy) {
    document.body.classList.toggle('busy', busy);
  }

  function dataDateText() {
    if (meta.sourceLastWriteTime) {
      return `源数据 ${meta.sourceLastWriteTime}`;
    }
    if (meta.generatedAt) {
      return `生成 ${meta.generatedAt}`;
    }
    return '';
  }

  function countCompanies(items) {
    return new Set(items.map((item) => item.displayCompany).filter(Boolean)).size;
  }

  function normalize(value) {
    return String(value || '')
      .normalize('NFKC')
      .toLowerCase()
      .replace(/\s+/g, ' ')
      .trim();
  }

  function includesText(value, text) {
    return String(value || '').includes(text);
  }

  function compact(values) {
    return values.map((value) => String(value || '').trim()).filter(Boolean);
  }

  function line(value, className) {
    return value ? `<div class="${className}">${escapeHtml(value)}</div>` : '';
  }

  function detail(label, value) {
    return value ? `<span><strong>${escapeHtml(label)}：</strong>${escapeHtml(value)}</span>` : '';
  }

  function badge(value, tone) {
    if (!value) {
      return '';
    }
    const className = tone ? `badge ${tone}` : 'badge';
    return `<span class="${className}">${escapeHtml(value)}</span>`;
  }

  function cleanPhone(value) {
    return String(value || '').replace(/[^\d+]/g, '');
  }

  function normalizeWebsite(value) {
    const site = String(value || '').trim();
    if (!site) {
      return '';
    }
    return /^https?:\/\//i.test(site) ? site : `https://${site}`;
  }

  function shortPdf(value) {
    const text = String(value || '');
    const parts = text.split(/[\\/]/);
    return parts[parts.length - 1] || text;
  }

  function formatDate(date) {
    const pad = (value) => String(value).padStart(2, '0');
    return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}`;
  }

  function messageFrom(error) {
    return String(error && error.message ? error.message : error);
  }

  function escapeHtml(value) {
    return String(value || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }

  function escapeAttribute(value) {
    return escapeHtml(value);
  }
})();
