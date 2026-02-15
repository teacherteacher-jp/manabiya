import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "panel", "overlay"]

  initialize() {
    this.isClosing = false
  }

  open() {
    this.isClosing = false
    document.body.style.overflow = "hidden"
    this.containerTarget.classList.remove("hidden")
    requestAnimationFrame(() => {
      this.panelTarget.classList.remove("translate-y-full")
      this.overlayTarget.classList.remove("opacity-0")
    })
  }

  close() {
    this.isClosing = true
    this.panelTarget.classList.add("translate-y-full")
    this.overlayTarget.classList.add("opacity-0")
    this.panelTarget.addEventListener("transitionend", () => {
      if (this.isClosing) {
        this.containerTarget.classList.add("hidden")
        document.body.style.overflow = ""
      }
    }, { once: true })
  }
}
