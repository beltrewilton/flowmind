
export default GoogleAuthPopup = {
  mounted() {
    this.el.addEventListener("click", (e) => {
      e.preventDefault();

      const url = "/google_auth_url"; // we'll make this route in a moment
      window.open(
        url,
        "Google Login",
        "width=500,height=600,left=200,top=100"
      );
    });
  },
};

