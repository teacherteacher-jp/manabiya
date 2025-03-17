import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "counter", "submit"]
  static values = { max: { type: Number, default: 1000 } }

  connect() {
    this.updateCounter()
  }

  updateCounter() {
    const currentLength = this.inputTarget.value.length
    this.counterTarget.firstElementChild.textContent = currentLength

    if (currentLength > this.maxValue) {
      this.submitTarget.disabled = true
      this.counterTarget.classList.add("text-red-500")
      this.counterTarget.classList.remove("text-gray-500")
    } else {
      this.submitTarget.disabled = false
      this.counterTarget.classList.add("text-gray-500")
      this.counterTarget.classList.remove("text-red-500")
    }
  }
}