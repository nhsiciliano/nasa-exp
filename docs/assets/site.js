// NASA Exp landing: tabs, nav jumps, feature filter, FAQ close animation and the App Store
// button. Everything here is an enhancement; the pages are complete without it.

// Fill in once the app is live (https://apps.apple.com/app/id6827700435). Every [data-cta]
// turns from "Coming soon" into a link. Until then the buttons stay as plain text.
const APP_STORE_URL = "";

(() => {
  "use strict";

  const root = document.documentElement;
  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
  const canTransition = () => typeof document.startViewTransition === "function" && !reducedMotion.matches;

  // Runs `update` inside a same-document view transition tagged with `kind`, or directly.
  // `data-vt` on <html> tells the CSS which names and animations apply; it is removed
  // when the transition ends, whatever the outcome.
  function transition(kind, update) {
    if (!canTransition()) {
      update();
      return null;
    }

    root.dataset.vt = kind;
    const vt = document.startViewTransition(update);
    vt.finished.finally(() => {
      if (root.dataset.vt === kind) {
        delete root.dataset.vt;
      }
    });
    return vt;
  }

  // ---------- App Store buttons ----------

  function setUpCallsToAction() {
    if (!APP_STORE_URL) {
      return;
    }

    document.querySelectorAll("[data-cta]").forEach((placeholder) => {
      const link = document.createElement("a");
      link.className = placeholder.className.replace("is-soon", "").trim();
      link.href = APP_STORE_URL;
      link.innerHTML = placeholder.innerHTML;
      link.querySelector("[data-cta-label]").textContent = placeholder.dataset.liveLabel;
      placeholder.replaceWith(link);
    });
  }

  // ---------- Explore tabs ----------

  function setUpTabs() {
    const tabs = document.querySelector("[data-tabs]");
    if (!tabs) {
      return;
    }

    const buttons = [...tabs.querySelectorAll('[role="tab"]')];
    const panels = buttons.map((button) => document.getElementById(button.getAttribute("aria-controls")));
    let current = 0;

    panels.forEach((panel, index) => {
      panel.setAttribute("role", "tabpanel");
      panel.setAttribute("aria-labelledby", buttons[index].id);
      panel.tabIndex = 0;
      panel.hidden = index !== current;
    });

    function show(index) {
      buttons.forEach((button, i) => {
        const selected = i === index;
        button.setAttribute("aria-selected", String(selected));
        button.tabIndex = selected ? 0 : -1;
      });
      panels.forEach((panel, i) => {
        panel.hidden = i !== index;
      });
    }

    function select(index, { focus = false } = {}) {
      if (index === current) {
        return;
      }

      const direction = index > current ? "tab-forward" : "tab-back";
      current = index;
      if (focus) {
        buttons[index].focus();
      }
      transition(direction, () => show(index));
    }

    buttons.forEach((button, index) => {
      button.addEventListener("click", () => select(index));
      button.addEventListener("keydown", (event) => {
        const last = buttons.length - 1;
        const next = {
          ArrowRight: current === last ? 0 : current + 1,
          ArrowLeft: current === 0 ? last : current - 1,
          Home: 0,
          End: last,
        }[event.key];

        if (next !== undefined) {
          event.preventDefault();
          select(next, { focus: true });
        }
      });
    });

    show(current);
    tabs.classList.add("is-ready");
  }

  // ---------- Header nav jumps ----------

  function setUpNavJumps() {
    document.querySelectorAll('.site-nav a[href^="#"]').forEach((link) => {
      link.addEventListener("click", (event) => {
        const id = link.getAttribute("href").slice(1);
        const target = document.getElementById(id);
        if (!target || !canTransition() || event.metaKey || event.ctrlKey || event.shiftKey) {
          return; // plain anchor, smooth-scrolled by CSS when motion is allowed
        }

        event.preventDefault();
        const goingDown = target.getBoundingClientRect().top > 0;
        const heading = target.querySelector("h2");
        const vt = transition(goingDown ? "nav-down" : "nav-up", () => {
          history.pushState(null, "", "#" + id);
          target.scrollIntoView({ behavior: "instant", block: "start" });
        });

        vt.updateCallbackDone.then(() => heading?.focus({ preventScroll: true }));
      });
    });
  }

  // ---------- Feature filter ----------

  function setUpFilter() {
    const section = document.querySelector("[data-filter-section]");
    if (!section) {
      return;
    }

    const chips = [...section.querySelectorAll("[data-filter]")];
    const cards = [...section.querySelectorAll("[data-tags]")];
    const status = section.querySelector("[data-filter-status]");

    chips.forEach((chip) => {
      chip.addEventListener("click", () => {
        const filter = chip.dataset.filter;
        section.classList.add("is-filtering");
        chips.forEach((other) => other.setAttribute("aria-pressed", String(other === chip)));

        let shown = 0;
        let entering = 0;
        cards.forEach((card) => {
          const matches = filter === "all" || card.dataset.tags.split(" ").includes(filter);
          if (matches) {
            shown += 1;
            if (card.hidden) {
              card.style.setProperty("--i", String(entering));
              entering += 1;
            }
          }
          card.hidden = !matches;
        });

        if (status) {
          status.textContent = status.dataset.template.replace("{n}", String(shown));
        }
      });
    });
  }

  // ---------- FAQ: animated close ----------
  // Opening animates in CSS. To animate the close, the item keeps [open] while
  // .is-closing collapses its row, then closes when the transition ends (or after a
  // fallback timer). A second tap while closing cancels the close. With reduced motion
  // the summary is left alone and the element closes natively.

  function setUpFAQ() {
    document.querySelectorAll(".faq-list details").forEach((details) => {
      const summary = details.querySelector("summary");
      const panel = details.querySelector(".faq-panel");
      let timer = 0;

      function stopClosing() {
        clearTimeout(timer);
        panel.removeEventListener("transitionend", onTransitionEnd);
        details.classList.remove("is-closing");
      }

      function finishClosing() {
        stopClosing();
        details.open = false;
      }

      function onTransitionEnd(event) {
        if (event.target === panel && event.propertyName === "grid-template-rows") {
          finishClosing();
        }
      }

      summary.addEventListener("click", (event) => {
        if (reducedMotion.matches || !details.open) {
          return;
        }

        event.preventDefault();
        if (details.classList.contains("is-closing")) {
          stopClosing(); // second tap: reopen from wherever the row is
          return;
        }

        details.classList.add("is-closing");
        panel.addEventListener("transitionend", onTransitionEnd);
        timer = setTimeout(finishClosing, 700);
      });

      // Opened or closed some other way (find in page, script): drop a pending close.
      details.addEventListener("toggle", () => {
        if (details.classList.contains("is-closing")) {
          stopClosing();
        }
      });
    });
  }

  setUpCallsToAction();
  setUpTabs();
  setUpNavJumps();
  setUpFilter();
  setUpFAQ();
})();
