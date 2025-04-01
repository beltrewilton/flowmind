export default FocusOnInputText = {
  mounted() {
    window.addEventListener("phx:focus_on_input_text", (e) => {
      this.el.focus()
    });
  },
};
