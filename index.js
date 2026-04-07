import './style.css';

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
    let startY = 0;
    let currentY = 0;
    let isPulling = false;
    let isReloading = false;

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
        'transition:transform 0.18s ease, opacity 0.18s ease',
    ].join(';');

    const action = document.createElement('div');
    action.style.cssText = [
        'display:flex',
        'align-items:center',
        'justify-content:center',
        'gap:12px',
        'width:min(100%, 20rem)',
        `min-height:${MENU_HEIGHT}px`,
        'padding:0 16px',
        'border-radius:12px',
        'background:#FFFFFF',
        'color:var(--color-brand, #05131D)',
        'font-family:var(--font-sans, Outfit, system-ui, sans-serif)',
        'font-size:1.75rem',
        'font-weight:500',
        'line-height:1.5',
        'box-shadow:0 1px 2px rgba(5, 19, 29, 0.08)',
        'transition:background-color 0.15s ease, color 0.15s ease, box-shadow 0.15s ease, transform 0.15s ease',
        'transform:translateY(0)',
    ].join(';');

    const dot = document.createElement('span');
    dot.style.cssText = [
        'width:16px',
        'height:16px',
        'border-radius:999px',
        'flex-shrink:0',
        'background:#FAC80A',
        'opacity:0',
        'transition:opacity 0.15s ease',
    ].join(';');

    const label = document.createElement('span');
    label.textContent = 'Päivitä';

    action.appendChild(dot);
    action.appendChild(label);
    indicator.appendChild(action);
    document.documentElement.appendChild(indicator);

    function clearPullState() {
        isPulling = false;
        startY = 0;
        currentY = 0;
        indicator.style.transform = 'translateY(-100%)';
        indicator.style.opacity = '0';
        action.style.background = '#FFFFFF';
        action.style.boxShadow = '0 1px 2px rgba(5, 19, 29, 0.08)';
        action.style.color = 'var(--color-brand, #05131D)';
        action.style.transform = 'translateY(0)';
        dot.style.opacity = '0';
    }

    function navigateForRefresh() {
        isReloading = true;
        window.location.reload();
    }

    function updateIndicator(delta) {
        if (delta <= REVEAL_THRESHOLD) {
            indicator.style.transform = 'translateY(-100%)';
            indicator.style.opacity = '0';
            action.style.transform = 'translateY(0)';
            action.style.background = '#FFFFFF';
            action.style.boxShadow = '0 1px 2px rgba(5, 19, 29, 0.08)';
            action.style.color = 'var(--color-brand, #05131D)';
            dot.style.opacity = '0';
            return;
        }

        const progress = Math.min(
            (delta - REVEAL_THRESHOLD) / (MAX_PULL_DISTANCE - REVEAL_THRESHOLD),
            1
        );
        const translateY = Math.round((-100 + (100 * progress)) * 10) / 10;
        const isArmed = delta >= ARM_THRESHOLD;

        indicator.style.transform = `translateY(${translateY}%)`;
        indicator.style.opacity = '1';
        action.style.transform = `translateY(${Math.max(0, 10 - (progress * 10))}px)`;

        if (isArmed) {
            action.style.background = '#F3F4F6';
            action.style.boxShadow = '0 0 0 1px rgba(5, 19, 29, 0.08)';
            action.style.color = 'var(--color-brand, #05131D)';
            dot.style.opacity = '1';
        } else {
            action.style.background = '#FFFFFF';
            action.style.boxShadow = '0 1px 2px rgba(5, 19, 29, 0.08)';
            action.style.color = 'var(--color-brand, #05131D)';
            dot.style.opacity = '0';
        }
    }

    document.addEventListener('touchstart', function (e) {
        if (isReloading) return;
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
            updateIndicator(delta);
        } else {
            clearPullState();
        }
    }, { passive: true });

    document.addEventListener('touchend', function () {
        if (!isPulling) return;
        const delta = currentY - startY;
        clearPullState();
        if (delta >= ARM_THRESHOLD && !isReloading) {
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
