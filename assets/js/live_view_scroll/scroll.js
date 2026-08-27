function type_of_root(el) {
  const id = el.id;

  if (id == "infinite-scroll") {
    return null;
  } else {
    return document.querySelector("#customers_list_ancestor");
  }
}

let Hooks = {};

Hooks.InfiniteScroll = {
  page() {
    return Number(this.el.dataset.page);
  },
  no_more_queries() {
    return Number(this.el.dataset.no_more_queries);
  },
  loadMore(entries) {
    const target = entries[0];

    if (
      target.isIntersecting &&
      this.pending == this.page() &&
      this.no_more_queries() == 0
    ) {
      this.pending = this.pending + 1;
      this.pushEventTo(target.target, "load-more", {});
    }
  },
  mounted() {
    this.pending = this.page();
    this.observe();
  },
  observe() {
    this.observer?.disconnect();
    this.observer = new IntersectionObserver(
      (entries) => this.loadMore(entries),
      {
        root: type_of_root(this.el), // window by default
        rootMargin: "0px",
        threshold: 1.0,
      },
    );
    this.observer.observe(this.el);
  },
  destroyed() {
    this.observer.disconnect();
  },
  updated() {
    this.pending = this.page();
    this.observe();
  },
};

export default Hooks;
