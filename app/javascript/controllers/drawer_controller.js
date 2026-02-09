import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "panel", "overlay"]

  open() {
    document.body.style.overflow = "hidden"
    this.containerTarget.classList.remove("hidden")
    requestAnimationFrame(() => {
      this.panelTarget.classList.remove("-translate-x-full")
      this.overlayTarget.classList.remove("opacity-0")
    })
  }

  close() {
    this.panelTarget.classList.add("-translate-x-full")
    this.overlayTarget.classList.add("opacity-0")
    this.panelTarget.addEventListener("transitionend", () => {
      this.containerTarget.classList.add("hidden")
      document.body.style.overflow = ""
    }, { once: true })
  }
}
