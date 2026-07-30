import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "input", "results"]

  connect() {
    this.debounceTimeout = null
  }

  submit() {
    clearTimeout(this.debounceTimeout)

    this.debounceTimeout = setTimeout(() => {
      if (this.inputTarget.value.trim().length >= 2) {
        this.formTarget.requestSubmit()
      } else {
        this.resultsTarget.innerHTML = ""
      }
    }, 300)
  }

  keydown(event) {
    if (event.key !== "Enter") return

    const links = this.resultsTarget.querySelectorAll("[data-car-search-target='resultLink']")
    if (links.length === 1) {
      event.preventDefault()
      window.location = links[0].href
    }
  }
}
