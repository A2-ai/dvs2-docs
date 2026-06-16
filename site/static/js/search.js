function debounce(fn, delay) {
    let timer;
    return function() {
        clearTimeout(timer);
        timer = setTimeout(() => fn.apply(this, arguments), delay);
    };
}

function compactText(value, limit) {
    return (value || "")
        .replace(/\s+/g, " ")
        .trim()
        .slice(0, limit);
}

function renderEmptyState(container, message) {
    container.innerHTML = "";
    const empty = document.createElement("p");
    empty.className = "search-empty";
    empty.textContent = message;
    container.appendChild(empty);
}

function initSearch() {
    const input = document.getElementById("search");
    if (!input) return;

    const searchContainer = document.querySelector(".site-search");
    const resultsItems = document.querySelector(".search-results__items");
    let index;

    fetch(window.MINIEXTENDR_SEARCH_INDEX_URL)
        .then(response => response.json())
        .then(data => {
            index = elasticlunr.Index.load(data);
        })
        .catch(() => {
            renderEmptyState(resultsItems, "Search index unavailable");
        });

    const doSearch = debounce(function() {
        const query = input.value.trim();
        if (!query) {
            searchContainer.classList.remove("has-results");
            return;
        }

        if (!index) {
            renderEmptyState(resultsItems, "Loading index...");
            searchContainer.classList.add("has-results");
            return;
        }

        const results = index.search(query, { expand: true });
        resultsItems.innerHTML = "";

        if (results.length === 0) {
            renderEmptyState(resultsItems, "No matching pages");
            searchContainer.classList.add("has-results");
            return;
        }

        results.slice(0, 8).forEach(result => {
            const doc = index.documentStore.getDoc(result.ref) || {};
            const link = document.createElement("a");
            const title = document.createElement("strong");
            const meta = document.createElement("span");
            const preview = compactText(doc.description || doc.body || result.ref, 150);

            link.className = "search-result";
            link.href = result.ref;
            title.className = "search-result__title";
            title.textContent = doc.title || result.ref;
            meta.className = "search-result__meta";
            meta.textContent = preview;

            link.appendChild(title);
            link.appendChild(meta);
            resultsItems.appendChild(link);
        });

        searchContainer.classList.add("has-results");
    }, 180);

    input.addEventListener("input", doSearch);
    input.addEventListener("focus", doSearch);

    document.addEventListener("click", function(event) {
        if (!event.target.closest(".site-search")) {
            searchContainer.classList.remove("has-results");
        }
    });

    document.addEventListener("keydown", function(event) {
        if (event.key === "Escape") {
            searchContainer.classList.remove("has-results");
            input.blur();
        }
    });
}

document.addEventListener("DOMContentLoaded", initSearch);
