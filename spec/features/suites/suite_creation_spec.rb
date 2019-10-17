# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Suite Creation' do
  before { log_in create(:admin) }

  it 'succeeds' do
    building = create(:building)
    navigate_to_view(building)
    fill_in_suite_info(suite_number: 'L01')
    click_on 'Create'
    expect(page).to have_content('L01')
  end
  it 'redirects to /new on failure' do
    visit new_building_suite_path(create(:building))
    click_on 'Create'
    expect(page).to have_content('errors')
  end

  def fill_in_suite_info(**attrs)
    attrs.each { |a, v| fill_in a.to_s, with: v }
  end

  def navigate_to_view(building)
    visit root_path
    click_on 'Inventory'
    first("a[href='#{building_path(building.id)}']").click
    click_on 'New Suite'
    expect(page).to have_content('Add Suite')
  end
end
