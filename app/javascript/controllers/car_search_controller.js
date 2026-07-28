import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "form", "input", "results"]

  connect() {
    this.debounceTimeout = null
    this.boundClickOutside = this.clickOutside.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClickOutside)
  }

  toggle() {
    const opening = this.containerTarget.classList.contains("hidden")
    this.containerTarget.classList.toggle("hidden")

    if (opening) {
      document.addEventListener("click", this.boundClickOutside)
      this.inputTarget.focus()
    } else {
      document.removeEventListener("click", this.boundClickOutside)
    }
  }

  close() {
    this.containerTarget.classList.add("hidden")
    document.removeEventListener("click", this.boundClickOutside)
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) this.close()
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
    if (event.key === "Escape") {
      this.close()
      return
    }

    if (event.key === "Enter") {
      const links = this.resultsTarget.querySelectorAll("[data-car-search-target='resultLink']")
      if (links.length === 1) {
        event.preventDefault()
        window.location = links[0].href
      }
    }
  }
}
