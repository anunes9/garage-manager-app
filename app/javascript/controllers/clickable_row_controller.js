import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  visit(event) {
    if (event.target.closest("a, button")) return

    Turbo.visit(this.urlValue)
  }
}
