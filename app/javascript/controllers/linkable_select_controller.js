import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    members: Array,
    students: Object
  }

  typeChanged(event) {
    const form = event.target.closest("form")
    const idSelect = form.querySelector('select[name="linkable_id"]')
    const type = event.target.value

    idSelect.innerHTML = '<option value="">選択してください</option>'

    if (type === "Member") {
      this.membersValue.forEach(member => {
        idSelect.add(new Option(member.name, member.id))
      })
    } else if (type === "Student") {
      for (const [groupName, students] of Object.entries(this.studentsValue)) {
        if (students.length === 0) continue
        const optgroup = document.createElement("optgroup")
        optgroup.label = groupName
        students.forEach(student => {
          optgroup.appendChild(new Option(student.name, student.id))
        })
        idSelect.add(optgroup)
      }
    }
  }
}
