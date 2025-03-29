export default ScrollBottom = {
  mounted() {
    window.addEventListener("phx:scrolldown", (e) => {
      this.el.scrollTo({ top: this.el.scrollHeight, behavior: "smooth" });
    });
  },

  updated() {
    // window.addEventListener("phx:scrolldown", (e) => {
    //   console.log("updated() scrolldown")
    //   console.log(e)
    // });
  //   const pixelsBelowBottom =
  //     this.el.scrollHeight - this.el.clientHeight - this.el.scrollTop;

  //   if (pixelsBelowBottom < this.el.clientHeight * 0.3) {
  //     this.el.scrollTo(0, this.el.scrollHeight);
  //   }
  },
};
