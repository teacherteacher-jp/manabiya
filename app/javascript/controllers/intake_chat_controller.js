import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "input", "submit", "placeholder"]
  static values = { sessionId: Number, status: String }

  connect() {
    this.eventSource = null

    if (this.statusValue === "in_progress" && !this.hasExistingMessages()) {
      this.startConversation()
    }
  }

  disconnect() {
    this.closeEventSource()
  }

  hasExistingMessages() {
    return this.messagesTarget.querySelectorAll(".rounded-lg.p-3").length > 0
  }

  startConversation() {
    this.removePlaceholder()
    const assistantDiv = this.createMessageDiv("assistant", "")
    const contentSpan = assistantDiv.querySelector(".content")
    this.messagesTarget.appendChild(assistantDiv)

    const url = `/intake_sessions/${this.sessionIdValue}/stream`
    this.streamResponse(url, contentSpan)
  }

  send(event) {
    event.preventDefault()

    const message = this.inputTarget.value.trim()
    if (!message) return

    this.appendMessage("user", message)
    this.inputTarget.value = ""
    this.submitTarget.disabled = true

    const assistantDiv = this.createMessageDiv("assistant", "")
    const contentSpan = assistantDiv.querySelector(".content")
    this.messagesTarget.appendChild(assistantDiv)
    this.scrollToBottom()

    const url = `/intake_sessions/${this.sessionIdValue}/stream?message=${encodeURIComponent(message)}`
    this.streamResponse(url, contentSpan)
  }

  streamResponse(url, contentSpan) {
    this.eventSource = new EventSource(url)

    this.eventSource.addEventListener("delta", (e) => {
      const text = e.data.replace(/\\n/g, "\n")
      contentSpan.textContent += text
      this.scrollToBottom()
    })

    this.eventSource.addEventListener("tool", (e) => {
      console.log("Tool used:", e.data)
      if (e.data === "complete_intake") {
        this.showGeneratingReport()
      }
    })

    this.eventSource.addEventListener("done", (e) => {
      this.closeEventSource()
      if (this.hasSubmitTarget) {
        this.submitTarget.disabled = false
      }

      if (e.data === "completed") {
        window.location.reload()
      }
    })

    this.eventSource.addEventListener("error", (e) => {
      if (e.data) {
        contentSpan.textContent = `エラー: ${e.data}`
      }
      this.closeEventSource()
      if (this.hasSubmitTarget) {
        this.submitTarget.disabled = false
      }
    })

    this.eventSource.onerror = () => {
      this.closeEventSource()
      if (this.hasSubmitTarget) {
        this.submitTarget.disabled = false
      }
    }
  }

  removePlaceholder() {
    if (this.hasPlaceholderTarget) {
      this.placeholderTarget.remove()
    }
  }

  appendMessage(role, content) {
    this.removePlaceholder()
    const div = this.createMessageDiv(role, content)
    this.messagesTarget.appendChild(div)
    this.scrollToBottom()
  }

  createMessageDiv(role, content) {
    const div = document.createElement("div")
    div.className = role === "user"
      ? "bg-rose-50 rounded-lg p-3"
      : "bg-gray-50 rounded-lg p-3"

    const label = document.createElement("div")
    label.className = "text-xs font-bold mb-1 " + (role === "user" ? "text-rose-600" : "text-gray-600")
    label.textContent = role === "user" ? "あなた" : "アシスタント"

    const contentSpan = document.createElement("div")
    contentSpan.className = "content whitespace-pre-wrap"
    contentSpan.textContent = content

    div.appendChild(label)
    div.appendChild(contentSpan)

    return div
  }

  showGeneratingReport() {
    const form = this.element.querySelector("form")
    if (form) {
      form.outerHTML = `
        <div class="bg-amber-50 border border-amber-200 rounded-lg p-4 text-center">
          <p class="text-amber-700 font-bold animate-pulse">レポートを作成しています...</p>
        </div>
      `
    }
  }

  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  closeEventSource() {
    if (this.eventSource) {
      this.eventSource.close()
      this.eventSource = null
    }
  }
}
