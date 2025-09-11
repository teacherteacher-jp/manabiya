import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "content", "warning"]

  connect() {
    this.checkForNames()
  }

  checkForNames() {
    if (!this.hasContentTarget || !this.hasWarningTarget) return

    const checkedStudents = this.getCheckedStudentNames()
    const content = this.contentTarget.value

    const foundNames = []

    checkedStudents.forEach(studentInfo => {
      const names = this.extractNamesFromStudent(studentInfo.name)

      names.forEach(name => {
        if (name.length > 1 && this.isNameInContent(name, content)) {
          foundNames.push(name)
        }
      })
    })

    if (foundNames.length > 0) {
      this.warningTarget.innerHTML = `
        <div class="bg-yellow-50 border border-yellow-200 rounded-md p-3 mt-2">
          <p class="text-sm text-yellow-800">
            ⚠️ メモ内容に生徒さんの名前が含まれている可能性があります:
            <strong>${foundNames.join("、")}</strong>
          </p>
          <p class="text-xs text-yellow-700 mt-1">
            プライバシー保護のため、名前は伏せて記載することをご検討ください。
          </p>
        </div>
      `
      this.warningTarget.style.display = "block"
    } else {
      this.warningTarget.style.display = "none"
    }
  }

  getCheckedStudentNames() {
    const checkedStudents = []

    this.checkboxTargets.forEach(checkbox => {
      if (checkbox.checked) {
        const label = checkbox.parentElement.querySelector('label')
        if (label) {
          const nameDiv = label.querySelector('div.text-gray-900')
          if (nameDiv) {
            const nameText = nameDiv.textContent.trim()
            const name = nameText.split('(')[0].trim()
            checkedStudents.push({
              id: checkbox.value,
              name: name
            })
          }
        }
      }
    })

    return checkedStudents
  }

  extractNamesFromStudent(fullName) {
    const names = []

    // スペース区切りで姓名を分割
    const parts = fullName.split(/[\s　]+/)

    // 各パーツを追加
    parts.forEach(part => {
      if (part.length > 0) {
        names.push(part)
      }
    })

    // フルネームも追加
    names.push(fullName)

    return names
  }

  isNameInContent(name, content) {
    // ひらがなをカタカナに変換
    const nameKatakana = this.hiraganaToKatakana(name)
    // カタカナをひらがなに変換
    const nameHiragana = this.katakanaToHiragana(name)

    const contentLower = content.toLowerCase()
    const nameLower = name.toLowerCase()

    // 元の名前、ひらがな、カタカナ、小文字のいずれかが含まれているかチェック
    return content.includes(name) ||
           content.includes(nameKatakana) ||
           content.includes(nameHiragana) ||
           contentLower.includes(nameLower)
  }

  hiraganaToKatakana(str) {
    return str.replace(/[\u3041-\u3096]/g, function(match) {
      const chr = match.charCodeAt(0) + 0x60
      return String.fromCharCode(chr)
    })
  }

  katakanaToHiragana(str) {
    return str.replace(/[\u30a1-\u30f6]/g, function(match) {
      const chr = match.charCodeAt(0) - 0x60
      return String.fromCharCode(chr)
    })
  }

  checkboxChanged() {
    this.checkForNames()
  }

  contentChanged() {
    this.checkForNames()
  }
}
