import './style.css';

function setupPullToRefresh() {
    if (window.__pullToRefreshSetup) return;
    window.__pullToRefreshSetup = true;

    const isStandalone =
        window.matchMedia('(display-mode: standalone)').matches ||
        window.navigator.standalone === true;
    if (!isStandalone) return;

    const THRESHOLD = 64;
    const RELOAD_THRESHOLD = THRESHOLD * 1.5;
    const RELOAD_COOLDOWN_MS = 10000;
    const RELOAD_KEY = 'pwa-pull-to-refresh-reload-at';
    let startY = 0;
    let currentY = 0;
    let isPulling = false;
    let isReloading = false;
    let reloadCooldownUntil = 0;

    try {
        const previousReloadAt = Number(window.sessionStorage.getItem(RELOAD_KEY) || '0');
        if (Number.isFinite(previousReloadAt) && previousReloadAt > 0) {
            reloadCooldownUntil = previousReloadAt + RELOAD_COOLDOWN_MS;
        }
    } catch (_error) {
        reloadCooldownUntil = 0;
    }

    const indicator = document.createElement('div');
    indicator.setAttribute('aria-hidden', 'true');
    indicator.style.cssText = [
        'position:fixed',
        'top:0',
        'left:0',
        'right:0',
        'height:0',
        'overflow:hidden',
        'display:flex',
        'align-items:center',
        'justify-content:center',
        'background:#fff',
        'color:#05131D',
        'font-family:system-ui,sans-serif',
        'font-size:1.75rem',
        'z-index:9999',
        'transition:height 0.15s ease',
        'pointer-events:none',
        'user-select:none',
    ].join(';');
    document.documentElement.appendChild(indicator);

    function clearPullState() {
        isPulling = false;
        startY = 0;
        currentY = 0;
        indicator.style.height = '0';
    }

    function isCoolingDown() {
        return Date.now() < reloadCooldownUntil;
    }

    function navigateForRefresh() {
        const refreshAt = Date.now();
        reloadCooldownUntil = refreshAt + RELOAD_COOLDOWN_MS;
        isReloading = true;

        try {
            window.sessionStorage.setItem(RELOAD_KEY, String(refreshAt));
        } catch (_error) {
            // Ignore sessionStorage failures; the in-memory guard still prevents rapid loops.
        }

        window.location.reload();
    }

    document.addEventListener('touchstart', function (e) {
        if (isReloading || isCoolingDown()) return;
        if (e.touches.length !== 1) {
            clearPullState();
            return;
        }

        if (window.scrollY === 0) {
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
            const h = Math.min(delta * 0.5, THRESHOLD);
            indicator.style.height = h + 'px';
            indicator.textContent = delta > RELOAD_THRESHOLD
                ? '✓ Vapauta päivittymään'
                : '↓ Vedä päivittääksesi';
        } else {
            clearPullState();
        }
    }, { passive: true });

    document.addEventListener('touchend', function () {
        if (!isPulling) return;
        const delta = currentY - startY;
        clearPullState();
        if (delta > RELOAD_THRESHOLD && !isReloading && !isCoolingDown()) {
            setTimeout(navigateForRefresh, 150);
        }
    }, { passive: true });

    document.addEventListener('touchcancel', clearPullState, { passive: true });
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
        setupPullToRefresh();
    },
    flags: function () {
        return null;
    },
};
export default config;
