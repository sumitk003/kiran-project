import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["salePriceLabel"]

  setImportantFields(event) {
    const checked = event.target.checked
    if (checked) {
      this.salePriceLabelTarget.innerHTML = `Sale price<span style="color: red;">*</span>`
    } else {
      this.salePriceLabelTarget.textContent = "Sale price"
    }
  }
}
