import './style.css';

const SEARCH_INDEX_URL = '/search-index.json';
const LUNR_SCRIPT_URL = '/vendor/lunr.min.js';
const LUNR_SCRIPT_ID = 'lunr-js-runtime';
const INLINE_SEARCH_ROOT_SELECTOR = '[data-search-widget]';
const INLINE_SEARCH_FORM_SELECTOR = '[data-search-widget-form]';
const INLINE_SEARCH_INPUT_SELECTOR = '[data-search-widget-input]';
const INLINE_SEARCH_RESULTS_SELECTOR = '[data-search-widget-results]';
const INLINE_SEARCH_DEBOUNCE_MS = 200;
const INLINE_SEARCH_MAX_RESULTS = 8;
let searchRuntimePromise = null;
let searchRuntime = null;
const inlineSearchTimers = new WeakMap();

function loadLunrRuntime() {
    if (window.lunr) {
        return Promise.resolve(window.lunr);
    }

    if (window.__lunrRuntimePromise) {
        return window.__lunrRuntimePromise;
    }

    window.__lunrRuntimePromise = new Promise(function (resolve, reject) {
        const existing = document.getElementById(LUNR_SCRIPT_ID);
        if (existing) {
            existing.addEventListener('load', function () { resolve(window.lunr); }, { once: true });
            existing.addEventListener('error', reject, { once: true });
            return;
        }

        const script = document.createElement('script');
        script.id = LUNR_SCRIPT_ID;
        script.src = LUNR_SCRIPT_URL;
        script.async = true;
        script.onload = function () {
            if (window.lunr) {
                resolve(window.lunr);
            } else {
                reject(new Error('lunr runtime loaded but window.lunr is missing'));
            }
        };
        script.onerror = reject;
        document.head.appendChild(script);
    });

    return window.__lunrRuntimePromise;
}

function ensureSearchRuntime() {
    if (!searchRuntimePromise) {
        searchRuntimePromise = loadLunrRuntime()
            .then(function (lunr) {
                return fetch(SEARCH_INDEX_URL)
                    .then(function (response) {
                        if (!response.ok) {
                            throw new Error('Search index request failed with status ' + response.status);
                        }
                        return response.json();
                    })
                    .then(function (documents) {
                        const documentsById = new Map(
                            documents.map(function (doc) {
                                return [doc.id, doc];
                            })
                        );

                        const index = lunr(function () {
                            this.ref('id');
                            this.field('title', { boost: 20 });
                            this.field('description', { boost: 10 });
                            this.field('body');
                            documents.forEach(function (doc) { this.add(doc); }, this);
                        });

                        const runtime = { documents: documents, documentsById: documentsById, index: index };
                        searchRuntime = runtime;
                        return runtime;
                    });
            })
            .catch(function (error) {
                searchRuntimePromise = null;
                throw error;
            });
    }

    return searchRuntimePromise;
}

function escapeLunrTerm(term) {
    return term.replace(/[+\-!(){}\[\]^"~*?:\\/]/g, '\\$&');
}

function buildLunrQuery(rawQuery) {
    const terms = rawQuery
        .trim()
        .split(/\s+/)
        .map(function (term) { return term.trim(); })
        .filter(Boolean)
        .map(escapeLunrTerm);

    if (terms.length === 0) {
        return '';
    }

    return terms.map(function (term) { return term + '*'; }).join(' ');
}

function fallbackSearch(rawQuery, runtime) {
    const query = rawQuery.trim().toLowerCase();
    if (!query) {
        return [];
    }

    return runtime.documents
        .filter(function (doc) {
            const haystack = (doc.title + ' ' + doc.description + ' ' + doc.body).toLowerCase();
            return haystack.includes(query);
        })
        .map(function (doc) { return doc.id; });
}

function runSearch(rawQuery, runtime) {
    const query = buildLunrQuery(rawQuery);
    if (!query) {
        return [];
    }

    try {
        return runtime.index.search(query).map(function (result) { return result.ref; });
    } catch (_error) {
        return fallbackSearch(rawQuery, runtime);
    }
}

function mapSearchResults(ids, runtime) {
    return ids
        .map(function (id) { return runtime.documentsById.get(id); })
        .filter(Boolean)
        .map(function (doc) {
            return {
                path: doc.path,
                title: doc.title,
                description: doc.description,
            };
        });
}

function getInlineSearchElements(root) {
    if (!root) {
        return null;
    }

    const form = root.querySelector(INLINE_SEARCH_FORM_SELECTOR);
    const input = root.querySelector(INLINE_SEARCH_INPUT_SELECTOR);
    const results = root.querySelector(INLINE_SEARCH_RESULTS_SELECTOR);

    if (!form || !input || !results) {
        return null;
    }

    return { form: form, input: input, results: results };
}

function clearInlineSearchTimer(root) {
    const existing = inlineSearchTimers.get(root);
    if (existing) {
        clearTimeout(existing);
        inlineSearchTimers.delete(root);
    }
}

function inlineSearchResultsLink(query) {
    return '/haku?q=' + encodeURIComponent(query);
}

function createInlineResultsSummary(results) {
    const summary = document.createElement('p');
    summary.className = 'search-widget-summary';
    summary.textContent = results.length + ' hakutulosta';
    return summary;
}

function createInlineResultItem(result) {
    const item = document.createElement('li');
    item.className = 'search-widget-item';
    const title = document.createElement('h3');
    title.className = 'search-widget-title';
    const link = document.createElement('a');
    link.className = 'search-widget-link';
    const description = document.createElement('p');
    description.className = 'search-widget-description';

    link.href = result.path;
    link.textContent = result.title;
    description.textContent = result.description;

    title.appendChild(link);
    item.appendChild(title);
    item.appendChild(description);
    return item;
}

function createInlineShowAllLink(query) {
    const wrapper = document.createElement('p');
    wrapper.className = 'search-widget-show-all';
    const link = document.createElement('a');
    link.className = 'search-widget-link search-widget-link-all';

    link.href = inlineSearchResultsLink(query);
    link.textContent = 'Näytä kaikki tulokset';
    wrapper.appendChild(link);
    return wrapper;
}

function renderInlineSearchHint(root) {
    const elements = getInlineSearchElements(root);
    if (!elements) {
        return;
    }

    elements.results.replaceChildren();

    const hint = document.createElement('p');
    hint.className = 'search-widget-hint';
    hint.textContent = 'Kirjoita hakusana ja tulokset päivittyvät automaattisesti.';
    elements.results.appendChild(hint);
}

function renderInlineSearchRuntimeFallback(root, query) {
    const elements = getInlineSearchElements(root);
    if (!elements) {
        return;
    }

    elements.results.replaceChildren();

    const message = document.createElement('p');
    message.className = 'search-widget-state';
    message.textContent = 'Live-haku ei ole juuri nyt saatavilla.';
    elements.results.appendChild(message);
    elements.results.appendChild(createInlineShowAllLink(query));
}

function renderInlineSearchResults(root, query, results) {
    const elements = getInlineSearchElements(root);
    if (!elements) {
        return;
    }

    elements.results.replaceChildren();

    const limitedResults = results.slice(0, INLINE_SEARCH_MAX_RESULTS);

    if (limitedResults.length > 0) {
        const list = document.createElement('ul');
        list.className = 'search-widget-list';
        elements.results.appendChild(createInlineResultsSummary(limitedResults));
        limitedResults.forEach(function (result) {
            list.appendChild(createInlineResultItem(result));
        });
        elements.results.appendChild(list);
    } else {
        const empty = document.createElement('p');
        empty.className = 'search-widget-state';
        empty.textContent = 'Ei hakutuloksia.';
        elements.results.appendChild(empty);
    }

    elements.results.appendChild(createInlineShowAllLink(query));
}

function runInlineSearch(root, rawQuery) {
    const query = rawQuery.trim();
    if (!query) {
        renderInlineSearchHint(root);
        return;
    }

    ensureSearchRuntime()
        .then(function (runtime) {
            const ids = runSearch(query, runtime);
            const results = mapSearchResults(ids, runtime);
            renderInlineSearchResults(root, query, results);
        })
        .catch(function () {
            renderInlineSearchRuntimeFallback(root, query);
        });
}

function setupInlineSearchWidgets() {
    if (window.__inlineSearchWidgetsSetup) {
        return;
    }
    window.__inlineSearchWidgetsSetup = true;

    document.addEventListener('input', function (event) {
        const target = event.target;
        if (!(target instanceof HTMLInputElement)) {
            return;
        }
        if (!target.matches(INLINE_SEARCH_INPUT_SELECTOR)) {
            return;
        }

        const root = target.closest(INLINE_SEARCH_ROOT_SELECTOR);
        if (!root) {
            return;
        }

        clearInlineSearchTimer(root);
        if (!target.value.trim()) {
            renderInlineSearchHint(root);
            return;
        }

        const timeoutId = setTimeout(function () {
            runInlineSearch(root, target.value);
        }, INLINE_SEARCH_DEBOUNCE_MS);
        inlineSearchTimers.set(root, timeoutId);
    });

    document.addEventListener('submit', function (event) {
        const target = event.target;
        if (!(target instanceof HTMLFormElement)) {
            return;
        }
        if (!target.matches(INLINE_SEARCH_FORM_SELECTOR)) {
            return;
        }

        const root = target.closest(INLINE_SEARCH_ROOT_SELECTOR);
        const elements = getInlineSearchElements(root);
        if (!elements) {
            return;
        }

        const query = elements.input.value.trim();
        if (!query) {
            return;
        }

        if (searchRuntime) {
            event.preventDefault();
            clearInlineSearchTimer(root);
            const ids = runSearch(query, searchRuntime);
            const results = mapSearchResults(ids, searchRuntime);
            renderInlineSearchResults(root, query, results);
        } else {
            ensureSearchRuntime().catch(function () {
                return null;
            });
        }
    });
}

function setupPullToRefresh() {
    if (window.__pullToRefreshSetup) return;
    window.__pullToRefreshSetup = true;

    const isStandalone =
        window.matchMedia('(display-mode: standalone)').matches ||
        window.navigator.standalone === true;
    if (!isStandalone) return;

    const REVEAL_THRESHOLD = 20;
    const ARM_THRESHOLD = 148;
    const MAX_PULL_DISTANCE = 196;
    const MENU_HEIGHT = 52;
    const IMMEDIATE_REARM_MS = 400;
    let startY = 0;
    let currentY = 0;
    let isPulling = false;
    let isReloading = false;
    let allowPullUntil = 0;

    const indicator = document.createElement('div');
    indicator.setAttribute('aria-hidden', 'true');
    indicator.style.cssText = [
        'position:fixed',
        'top:0',
        'left:0',
        'right:0',
        'height:72px',
        'display:flex',
        'justify-content:center',
        'padding:8px 16px 12px',
        'z-index:9999',
        'pointer-events:none',
        'user-select:none',
        'transform:translateY(-100%)',
        'opacity:0',
        'margin-top:2rem',
    ].join(';');

    const action = document.createElement('div');
    action.style.cssText = [
        'display:flex',
        'align-items:center',
        'justify-content:center',
        'width:min(100%, 20rem)',
        `min-height:${MENU_HEIGHT}px`,
        'padding:0 16px',
        'color:#000000',
        'font-family:var(--font-sans, Outfit, system-ui, sans-serif)',
        'font-size:1.75rem',
        'font-weight:500',
        'line-height:1.5',
        'opacity:0.3',
        'border-bottom:2px solid transparent',
        'transform:translateY(0)',
    ].join(';');

    const label = document.createElement('span');
    label.textContent = '⟳ Päivitä sivu';

    action.appendChild(label);
    indicator.appendChild(action);
    document.documentElement.appendChild(indicator);

    function clearPullState() {
        isPulling = false;
        startY = 0;
        currentY = 0;
        indicator.style.transform = 'translateY(-100%)';
        indicator.style.opacity = '0';
        action.style.opacity = '0.3';
        action.style.borderBottomColor = 'transparent';
        action.style.transform = 'translateY(0)';
    }

    function updateIndicator(delta) {
        if (delta <= REVEAL_THRESHOLD) {
            indicator.style.transform = 'translateY(-100%)';
            indicator.style.opacity = '0';
            return;
        }

        const progress = Math.min(
            (delta - REVEAL_THRESHOLD) / (MAX_PULL_DISTANCE - REVEAL_THRESHOLD),
            1
        );
        const translateY = -100 + 100 * progress;
        const isArmed = delta >= ARM_THRESHOLD;

        indicator.style.transform = `translateY(${translateY}%)`;
        indicator.style.opacity = '1';
        action.style.transform = `translateY(${Math.max(0, 10 - (progress * 10))}px)`;

        if (isArmed) {
            action.style.opacity = '1';
            action.style.borderBottomColor = '#000000';
        } else {
            action.style.opacity = '0.3';
            action.style.borderBottomColor = 'transparent';
        }
    }

    document.addEventListener('touchstart', function (e) {
        if (isReloading) return;
        if (e.touches.length !== 1) {
            clearPullState();
            return;
        }

        const isAtTop = window.scrollY === 0;
        const isWithinRearmWindow = performance.now() <= allowPullUntil;

        if (isAtTop || isWithinRearmWindow) {
            startY = e.touches[0].clientY;
            currentY = startY;
            isPulling = true;
        }
    }, { passive: true });

    document.addEventListener('touchmove', function (e) {
        if (!isPulling) return;
        currentY = e.touches[0].clientY;
        const delta = currentY - startY;
        if (delta > 0) {
            updateIndicator(delta);
        } else {
            clearPullState();
        }
    }, { passive: true });

    document.addEventListener('touchend', function () {
        if (!isPulling) return;
        const delta = currentY - startY;
        allowPullUntil = performance.now() + IMMEDIATE_REARM_MS;
        clearPullState();
        if (delta >= ARM_THRESHOLD && !isReloading) {
            isReloading = true;
            setTimeout(() => window.location.reload(), 0);
        }
    }, { passive: true });

    document.addEventListener('touchcancel', function () {
        allowPullUntil = performance.now() + IMMEDIATE_REARM_MS;
        clearPullState();
    }, { passive: true });
}

const config = {
    load: async function (elmLoaded) {
        const app = await elmLoaded;

        app.ports.focusMobileNav.subscribe(function () {
            requestAnimationFrame(function () {
                const el = document.querySelector('#mobile-nav-active') || document.querySelector('#mobile-nav a');
                if (el) el.focus();
            });
        });

        if (app.ports.performSearch && app.ports.searchResults) {
            app.ports.performSearch.subscribe(function (query) {
                ensureSearchRuntime()
                    .then(function (runtime) {
                        const ids = runSearch(query, runtime);
                        app.ports.searchResults.send(mapSearchResults(ids, runtime));
                    })
                    .catch(function (error) {
                        console.error('Failed to execute search:', error);
                        app.ports.searchResults.send([]);
                    });
            });
        }

        setupInlineSearchWidgets();
        setupPullToRefresh();
    },
    flags: function () {
        return null;
    },
};
export default config;
