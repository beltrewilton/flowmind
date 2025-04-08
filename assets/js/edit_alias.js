export default EditAlias = {
  mounted() {
    this.el.focus()
    this.el.select()
    
    const sender_phone_number = this.el.dataset.senderphonenumber
    const elem = this.el
    
    this.el.addEventListener("keydown", event => {
      const input_value = elem.value
      if (event.key == "Enter" & sender_phone_number != input_value & input_value != "") {
        this.pushEvent("handle_change_alias", {'input_value': input_value, 'sender_phone_number': sender_phone_number})
      }
    })
    
    // this.el.addEventListener("keyup", event => { 
    //   const input_value = elem.value
    //   if (input_value == "") { 
    //     elem.value = sender_phone_number
    //   }
    // })
  },

  updated() {
    console.log("EditAlias updated")
  },
};
