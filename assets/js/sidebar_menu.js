export default SideBarMenu = {
  mounted() {
    this.el.addEventListener("click", (e) => {
      console.log("phx:fire_sidebar");
      // this.pushEvent("fire_sidebar", { some_data: "optional payload" });
      this.pushEventTo("#drawer-container-id", "fire_sidebar", { message: "hi" });
    });
  },
};
