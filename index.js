import './style.css';

function setupPullToRefresh() {
    const isStandalone =
        window.matchMedia('(display-mode: standalone)').matches ||
        window.navigator.standalone === true;
    if (!isStandalone) return;

    const THRESHOLD = 64;
    let startY = 0;
    let currentY = 0;
    let isPulling = false;

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
        'background:#05131D',
        'color:#fff',
        'font-family:system-ui,sans-serif',
        'font-size:0.875rem',
        'z-index:9999',
        'transition:height 0.15s ease',
        'pointer-events:none',
        'user-select:none',
    ].join(';');
    document.body.prepend(indicator);

    document.addEventListener('touchstart', function (e) {
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
            indicator.textContent = delta > THRESHOLD * 1.5
                ? '↻ Päivitä sivu'
                : '↓ Vedä päivittääksesi';
        }
    }, { passive: true });

    document.addEventListener('touchend', function () {
        if (!isPulling) return;
        isPulling = false;
        const delta = currentY - startY;
        indicator.style.height = '0';
        if (delta > THRESHOLD * 1.5) {
            setTimeout(function () { location.reload(); }, 150);
        }
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
        setupPullToRefresh();
    },
    flags: function () {
        return null;
    },
};
export default config;
