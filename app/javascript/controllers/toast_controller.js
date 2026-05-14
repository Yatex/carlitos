import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    delay: { type: Number, default: 4500 }
  }

  connect() {
    this.timeout = window.setTimeout(() => this.dismiss(), this.delayValue)
  }

  disconnect() {
    window.clearTimeout(this.timeout)
    window.clearTimeout(this.removeTimeout)
  }

  dismiss() {
    this.element.classList.add("opacity-0", "-translate-y-1")
    this.removeTimeout = window.setTimeout(() => this.element.remove(), 250)
  }
}
