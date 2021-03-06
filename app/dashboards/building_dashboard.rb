# frozen_string_literal: true

require 'administrate/base_dashboard'

# administrate dashboard for buildings
class BuildingDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    suites: Field::HasMany,
    id: Field::Number,
    full_name: Field::String,
    abbreviation: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i(
    full_name
    abbreviation
    suites
  ).freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i(
    suites
    id
    full_name
    abbreviation
    created_at
    updated_at
  ).freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i(
    suites
    full_name
    abbreviation
  ).freeze

  # Overwrite this method to customize how buildings are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(building)
    building.name
  end
end
