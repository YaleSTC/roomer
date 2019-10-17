# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Draw start lottery' do
  let!(:draw) { create(:draw_with_members, status: 'group_formation') }

  before do
    log_in create(:admin)
    create(:locked_group, leader: draw.students.first)
  end

  it 'can be done' do
    navigate_to_view
    click_on 'Proceed to lottery'
    click_on 'Proceed to lottery'
    expect(page).to have_css('.flash-success',
                             text: 'You can now assign lottery numbers')
  end

  def navigate_to_view
    visit root_path
    first(:link, draw.name).click
  end
end
