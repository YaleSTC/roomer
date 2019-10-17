# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Building editing' do
  before { log_in create(:admin) }
  let!(:building) { create(:building) }

  it 'succeeds' do
    navigate_to_view
    new_name = 'TD'
    update_building_name(new_name)
    expect(page).to have_css('.building-name', text: new_name)
  end

  it 'redirects to /edit on failure' do
    visit edit_building_path(building)
    update_building_name('')
    expect(page).to have_content("can't be blank")
  end

  def update_building_name(new_name)
    fill_in 'building_name', with: new_name
    click_on 'Save'
  end

  def navigate_to_view
    visit root_path
    click_on 'Inventory'
    find("a[href='#{edit_building_path(building.id)}']").click
  end
end
