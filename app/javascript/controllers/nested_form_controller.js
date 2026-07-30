import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "parts"]

  add(event) {
    event.preventDefault()
    const newId = new Date().getTime()
    const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, newId)
    this.partsTarget.insertAdjacentHTML("beforeend", html)
  }

  remove(event) {
    event.preventDefault()
    const wrapper = event.target.closest(".part-fields")
    if (wrapper.dataset.newRecord === "true") {
      wrapper.remove()
    } else {
      wrapper.querySelector("input[name*='_destroy']").value = "1"
      wrapper.style.display = "none"
    }
  }
}
