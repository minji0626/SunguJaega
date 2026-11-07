/* 선구복지센터 공통 스크립트
   - 모바일 메뉴 열기/닫기
   - 오시는 길 페이지의 네이버 지도 표시 */
document.addEventListener("DOMContentLoaded", () => {
    /* ---------- 모바일 메뉴 ---------- */
    const toggle = document.getElementById("menuToggle");
    const nav = document.getElementById("siteNav");

    const setMenu = open => {
        if (!toggle || !nav) return;
        nav.classList.toggle("is-open", open);
        toggle.setAttribute("aria-expanded", String(open));
    };

    toggle?.addEventListener("click", () => {
        setMenu(toggle.getAttribute("aria-expanded") !== "true");
    });

    // Esc 키로 메뉴 닫기 후 버튼으로 초점 복귀
    document.addEventListener("keydown", e => {
        if (e.key === "Escape" && nav?.classList.contains("is-open")) {
            setMenu(false);
            toggle?.focus();
        }
    });

    /* ---------- 네이버 지도 ---------- */
    const mapEl = document.getElementById("naverMap");
    if (!mapEl) return;

    const address = mapEl.dataset.address || "";
    const title = mapEl.dataset.title || "선구복지센터";

    // 지도 표시 실패 시 안내 문구를 보여줌 (아래 지도 앱 버튼은 그대로 사용 가능)
    const showFallback = () => {
        mapEl.innerHTML =
            '<div class="map-fallback"><p>지도를 불러오지 못했습니다.<br>아래 버튼으로 네이버지도나 카카오맵에서 확인해 주세요.</p></div>';
    };

    if (!window.naver?.maps) {
        showFallback();
        return;
    }

    // 좌표로 지도와 마커를 그림
    const drawMap = (lat, lng) => {
        const position = new naver.maps.LatLng(lat, lng);
        const map = new naver.maps.Map(mapEl, {
            center: position,
            zoom: 16,
            zoomControl: true,
            zoomControlOptions: { position: naver.maps.Position.TOP_RIGHT },
        });
        const marker = new naver.maps.Marker({ position, map, title });
        const info = new naver.maps.InfoWindow({
            content: `<div style="padding:10px 12px;font-size:14px;line-height:1.5;"><strong>${title}</strong><br>${address}</div>`,
            borderWidth: 0,
            disableAnchor: true,
        });
        naver.maps.Event.addListener(marker, "click", () => info.open(map, marker));
        info.open(map, marker);
    };

    // data-lat / data-lng 가 있으면 그 좌표를 우선 사용
    const lat = parseFloat(mapEl.dataset.lat);
    const lng = parseFloat(mapEl.dataset.lng);
    if (!Number.isNaN(lat) && !Number.isNaN(lng)) {
        drawMap(lat, lng);
        return;
    }

    // 좌표가 없으면 주소로 좌표를 조회 (NCP Geocoding API 사용 설정 필요)
    if (!naver.maps.Service?.geocode) {
        showFallback();
        return;
    }
    naver.maps.Service.geocode({ query: address }, (status, response) => {
        const item = response?.v2?.addresses?.[0];
        if (status !== naver.maps.Service.Status.OK || !item) {
            showFallback();
            return;
        }
        drawMap(parseFloat(item.y), parseFloat(item.x));
    });
});
