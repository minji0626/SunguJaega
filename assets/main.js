document.addEventListener("DOMContentLoaded", () => {
    /* 슬라이더 */
    const slides = Array.from(document.querySelectorAll(".slide"));
    let slideIndex = 0;

    function rotateSlides() {
        if (!slides.length) return;
        slides.forEach((slide, idx) => {
            slide.classList.toggle("active", idx === slideIndex);
        });
        slideIndex = (slideIndex + 1) % slides.length;
    }
    rotateSlides();
    setInterval(rotateSlides, 5000);

    /* 모바일 메뉴 */
    const menuBtn = document.getElementById("menuBtn");
    const mobileMenu = document.getElementById("mobileMenu");
    const closeMenu = document.getElementById("closeMenu");

    menuBtn?.addEventListener("click", () => mobileMenu?.classList.add("open"));
    closeMenu?.addEventListener("click", () => mobileMenu?.classList.remove("open"));

    /* 모바일 드롭다운 */
    document.querySelectorAll(".m-dropdown > a").forEach(trigger => {
        trigger.addEventListener("click", e => {
            e.preventDefault();
            trigger.parentElement?.classList.toggle("open");
        });
    });

    /* 맨 위로 이동 버튼 */
    const toTopBtn = document.getElementById("toTop");
    window.addEventListener("scroll", () => {
        if (window.scrollY > 300) {
            toTopBtn?.classList.add("show");
        } else {
            toTopBtn?.classList.remove("show");
        }
    });
    toTopBtn?.addEventListener("click", () => {
        window.scrollTo({ top: 0, behavior: "smooth" });
    });

    /* 내비게이션 활성화 표시 */
    const currentPath = (() => {
        const parts = location.pathname.split("/").filter(Boolean);
        const last = parts.pop() || "index";
        return last.replace(/\.html$/i, "");
    })();

    const normalizeHref = href => {
        if (!href || /^https?:/i.test(href)) return null;
        const base = href.split("#")[0]
            .replace(/^\.\//, "")
            .replace(/^\//, "")
            .replace(/\.html$/i, "")
            .replace(/\/$/, "");
        return base || "index";
    };

    const setActive = selector => {
        document.querySelectorAll(selector).forEach(link => {
            const normalized = normalizeHref(link.getAttribute("href"));
            if (!normalized) return;
            if (normalized === currentPath) {
                link.classList.add("active");
            }
        });
    };
    setActive(".nav-menu a, .mobile-menu a");

    /* 스크롤 애니메이션 */
    const observer = new IntersectionObserver(entries => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add("in-view");
                observer.unobserve(entry.target);
            }
        });
    }, { threshold: 0.15 });

    document.querySelectorAll(".reveal, .card, .role-item, .metric-card, .callout-card, .content-card, .service-detail, .map-card")
        .forEach(el => {
            if (!el.classList.contains("reveal")) {
                el.classList.add("reveal");
            }
            observer.observe(el);
        });

    /* 네이버 지도 초기화 */
    const naverMapEl = document.getElementById("naverMap");
    if (naverMapEl && window.naver?.maps) {
        const lat = parseFloat(naverMapEl.dataset.lat || "0");
        const lng = parseFloat(naverMapEl.dataset.lng || "0");
        const title = naverMapEl.dataset.title || "위치";

        const position = new naver.maps.LatLng(lat, lng);
        const map = new naver.maps.Map(naverMapEl, {
            center: position,
            zoom: 16,
            zoomControl: true,
            zoomControlOptions: {
                position: naver.maps.Position.TOP_RIGHT,
            },
        });

        const marker = new naver.maps.Marker({
            position,
            map,
        });

        const infoWindow = new naver.maps.InfoWindow({
            content: `
                <div style="padding:10px;font-size:14px;line-height:1.5;">
                    <strong>${title}</strong><br>
                    경기도 양평군 용문면 용문로 323, 2층
                </div>
            `,
            borderWidth: 0,
            disableAnchor: true,
            backgroundColor: "#fff",
        });

        naver.maps.Event.addListener(marker, "click", () => {
            infoWindow.open(map, marker);
        });

        infoWindow.open(map, marker);
    }
});