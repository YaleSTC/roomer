# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Suite splitting' do
  let!(:building) { create(:building) }
  let!(:suite) { create(:suite_with_rooms, rooms_count: 2, building: building) }

  before { log_in create(:admin) }

  it 'can be performed' do
    initiate_suite_split
    fill_in_split_info(%w(new_suite_1 new_suite_2))
    expect(page).to have_css('.flash-success', text: 'Suite successfully split')
  end

  def initiate_suite_split
    visit building_path(building)
    click_on suite.number.to_s
    click_on 'Split suite'
  end

  def fill_in_split_info(suite_names)
    suite.rooms.each_with_index do |room, index|
      fill_in "suite_split_form_room_#{room.id}_suite", with: suite_names[index]
    end
    click_on 'Split suite'
  end
end
