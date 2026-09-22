(() => {
  const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  if (reduce) {
    document.documentElement.classList.add("reduce-motion");
    return;
  }

  document.documentElement.classList.add("motion-on");

  const staggerParents = document.querySelectorAll("[data-stagger]");
  staggerParents.forEach((parent) => {
    [...parent.children].forEach((child, index) => {
      child.style.setProperty("--i", String(index));
    });
  });

  const revealables = document.querySelectorAll(".reveal-scroll");
  if (!revealables.length) return;

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-visible");
          observer.unobserve(entry.target);
        }
      });
    },
    { rootMargin: "0px 0px -8% 0px", threshold: 0.12 }
  );

  revealables.forEach((node) => observer.observe(node));
})();
