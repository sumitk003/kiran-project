module ListingEnquiriesHelper
  def truncated_email(email, limit = 25)
    return unless email.present?
    email.length > limit ? "#{email[0...limit]}..." : email
  end

  def property_info(listing_enquiry)
    property = listing_enquiry.property
    if property.present?
      "#{property.name_label} - #{property.type_label} - #{property.number_and_street} #{property.city_and_state}"
    else
      "Could not find the corresponding property."
    end
  end
end
