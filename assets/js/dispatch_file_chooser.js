export default FileChooser = {
  mounted() {
    window.addEventListener("phx:fire_file_chooser", (e) => {
      document.querySelector(".live_file_input").click()
    });
  },
};
