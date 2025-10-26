# frozen_string_literal: true

module ContactSearchFormsHelper
  BUTTON_CLASSES = 'inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm
                    text-sm font-medium text-gray-700 bg-white hover:bg-gray-50
                    focus:outline-none focus:ring-2 focus:ring-offset-2
                    focus:ring-offset-gray-50 focus:ring-purple-500'.freeze

  def contact_search_form_tabs
    tabs = []

    tabs << tab('All', nil, params[:filter].nil?)
    tabs << tab('Individuals', 'individuals', params[:filter] == 'individuals')
    tabs << tab('Businesses', 'businesses', params[:filter] == 'businesses')

    %w(a b c d e f g h i j k l m n o p q r s t u v w x y z #).each do |letter|
      tabs << tab(letter.upcase, letter, params[:filter] == letter)
    end

    tabs
  end


  def new_contact_search_button
    contact_search_button('New Search', new_contact_search_form_path)
  end

  def new_individual_search_button
    contact_search_button('New Individual Search', new_contact_search_form_path(type: :individual))
  end

  def new_business_search_button
    contact_search_button('New Business Search', new_contact_search_form_path(type: :business))
  end

  def edit_contact_search_button(search_form)
    contact_search_button('Edit Search', [:edit, search_form], svg: edit_svg)
  end

  def contact_search_shared_by_different_agent?(search_form, current_agent)
    search_form.agent.id != current_agent.id
  end

  private

  # Generic button helper
  def contact_search_button(label, url, svg: plus_svg)
    content_tag(:span, class: 'block') do
      link_to(url, class: BUTTON_CLASSES, role: 'button') do
        concat svg.html_safe
        concat label
      end
    end
  end

  def tab(name, filter_value = nil, active = false)
    # Build URL with filter and current selected classifications
    url_params = {}
    url_params[:filter] = filter_value if filter_value.present?
    url_params[:contact_search_form] = { classifications: selected_classifications } if selected_classifications.any?

    url = contact_search_forms_path(url_params)

    PageTabComponent.new(name: name, url: url, active: active)
  end

  def selected_classifications
    # params[:contact_search_form][:classifications] ka fallback empty array
    params.dig(:contact_search_form, :classifications) || []
  end

  # Default SVG for "New" buttons
  def plus_svg
    <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg"
           class="-ml-1 mr-2 h-5 w-5 text-gray-400"
           fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M12 4v16m8-8H4" />
      </svg>
    SVG
  end

  # SVG for edit button
  def edit_svg
    <<~SVG
      <svg class="-ml-1 mr-2 h-5 w-5 text-gray-400"
           xmlns="http://www.w3.org/2000/svg"
           viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
        <path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793
                 -2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828
                 l8.38-8.379-2.83-2.828z" />
      </svg>
    SVG
  end
end
