import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    members: Object,
    students: Object
  }

  typeChanged(event) {
    const form = event.target.closest("form")
    const idSelect = form.querySelector('select[name="linkable_id"]')
    const type = event.target.value

    idSelect.innerHTML = '<option value="">選択してください</option>'

    const groups = { Member: this.membersValue, Student: this.studentsValue }[type]
    if (!groups) return

    for (const [groupName, items] of Object.entries(groups)) {
      if (items.length === 0) continue
      const optgroup = document.createElement("optgroup")
      optgroup.label = groupName
      items.forEach(item => {
        optgroup.appendChild(new Option(item.name, item.id))
      })
      idSelect.add(optgroup)
    }
  }
}
