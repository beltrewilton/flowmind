export default PartnerMetaLogin = {
  mounted() {
    window.fbAsyncInit = (function () {
      FB.init({
        appId: "982676389889672", // Replace with your Facebook App ID
        autoLogAppEvents: true,
        xfbml: true,
        version: "v22.0",
      });
    })(
    
    // Load the JavaScript SDK asynchronously
    (function (d, s, id) {
        var js, fjs = d.getElementsByTagName(s)[0];
        if (d.getElementById(id)) return;
        js = d.createElement(s);
        js.id = id;
        js.src = "https://connect.facebook.net/en_US/sdk.js";
        fjs.parentNode.insertBefore(js, fjs);
      })(document, "script", "facebook-jssdk"),
    );

    // Define the login callback function
    const fbLoginCallback = (response) => {
      this.pushEvent("dummy_event", {'data': 'mega dummy'});
      
      if (response.authResponse) {
        const code = response.authResponse.code;
        console.log('response: ', code); // remove after testing
        // TODO: Send the code to the server then from server to FB
        this.pushEvent("fb_login_success", { response });
      }
      document.getElementById("sdk-response").textContent = JSON.stringify(
        response,
        null,
        2,
      );
    };

    this.el.addEventListener("click", () => {
      FB.login(fbLoginCallback, {
        config_id: "356255260651856",
        response_type: "code",
        override_default_response_type: true,
        extras: {
          setup: {},
          featureType: "",
          sessionInfoVersion: "2",
        },
      });
    });

    window.addEventListener("message", (event) => {
      if (
        event.origin !== "https://www.facebook.com" &&
        event.origin !== "https://web.facebook.com"
      ) {
        return;
      }
      try {
        const data = JSON.parse(event.data);
        if (data.type === "WA_EMBEDDED_SIGNUP") {
          if (data.event === "FINISH") {
            this.pushEvent("whatsapp_signup_success", { data: data.data });
          } else if (data.event === "CANCEL") {
            console.warn("Cancelled at ", data.data);
          } else if (data.event === "ERROR") {
            console.error("Error:", data.data);
          }
        }
        document.getElementById("session-info-response").textContent =
          JSON.stringify(data, null, 2);
      } catch {
        console.log("Non JSON Responses", event.data);
      }
    });
  },
};
