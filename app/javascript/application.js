// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

document.addEventListener("turbo:load", function() {
  document.querySelectorAll(".status-selection img").forEach(function(img) {
    img.addEventListener("click", function() {
      const status = this.dataset.status;
      const date = this.dataset.date;
      const slot = this.dataset.slot;
      const hiddenField = document.getElementById(`${date}-${slot}-status`);
      hiddenField.value = status;

      this.parentElement.querySelectorAll("img").forEach(function(sibling) {
        sibling.classList.remove("selected");
      });

      this.classList.add("selected");
    });
  });
});
