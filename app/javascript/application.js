// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

document.addEventListener("turbo:load", function() {
  document.querySelectorAll(".status-selection button").forEach(function(button) {
    button.addEventListener("click", function() {
      const status = this.dataset.status;
      const date = this.dataset.date;
      const slot = this.dataset.slot;
      const hiddenField = document.getElementById(`${date}-${slot}-status`);
      hiddenField.value = status;

      this.parentElement.querySelectorAll("button").forEach(function(sibling) {
        sibling.classList.remove("selected");
      });

      this.classList.add("selected");
    });
  });

  const regionSelect = document.getElementById("member_region_region_id");

  if (regionSelect) {
    const submitButton = document.getElementById("new-member-region-form").querySelector("input[type='submit']");

    regionSelect.addEventListener("change", function() {
      if (regionSelect.value) {
        submitButton.disabled = false;
      } else {
        submitButton.disabled = true;
      }
    });
  }
});
