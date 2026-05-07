import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    fallback: { type: String, default: "America/Montevideo" },
    apply: { type: String, default: "when-fallback" }
  }

  connect() {
    const detectedTimeZone = Intl.DateTimeFormat().resolvedOptions().timeZone

    if (!detectedTimeZone || !this.hasOption(detectedTimeZone)) return
    if (!this.shouldApply()) return

    this.element.value = detectedTimeZone
    this.element.dispatchEvent(new Event("change", { bubbles: true }))
  }

  shouldApply() {
    if (this.applyValue === "always") return true

    return this.element.value === "" || this.element.value === this.fallbackValue
  }

  hasOption(value) {
    return Array.from(this.element.options).some((option) => option.value === value)
  }
}
