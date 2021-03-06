# frozen_string_literal: true

require 'administrate/base_dashboard'

# administrate dashboard for colleges
class CollegeDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    subdomain: Field::String,
    dean: Field::String,
    admin_email: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    floor_plan_url: Field::String,
    student_info_text: Field::Text,
    allow_clipping: Field::Boolean,
    restrict_clipping_group_size: Field::Boolean,
    advantage_clips: Field::Boolean,
    size_sort: EnumField
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i(
    name
    subdomain
    dean
    admin_email
  ).freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i(
    id
    name
    subdomain
    dean
    admin_email
    created_at
    updated_at
    floor_plan_url
    student_info_text
    allow_clipping
    restrict_clipping_group_size
    advantage_clips
    size_sort
  ).freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i(
    name
    subdomain
    dean
    admin_email
    floor_plan_url
    student_info_text
    allow_clipping
    restrict_clipping_group_size
    advantage_clips
    size_sort
  ).freeze

  # Overwrite this method to customize how colleges are displayed
  # across all pages of the admin dashboard.

  def display_resource(college)
    college.name
  end
end
