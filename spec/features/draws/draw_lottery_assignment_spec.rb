# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Draw lottery assignment', js: true do
  let(:draw) { FactoryGirl.create(:draw_in_lottery) }
  let(:group) { draw.groups.first }

  before { log_in FactoryGirl.create(:admin) }

  it 'can be performed' do
    visit draw_path(draw)
    click_on 'Assign lottery numbers'
    assign_lottery_number(group, 1)
    reload
    expect(lottery_number_saved?(page, group, 1)).to be_truthy
  end

  it 'can be removed' do
    group.update!(lottery_number: 2)
    visit lottery_draw_path(draw)
    assign_lottery_number(group, '')
    reload
    # expect(lottery_number_saved?(page, group, nil)).to be_truthy
    expect(group.reload.lottery_number).to be_nil
  end

  def assign_lottery_number(group, number)
    within("\#lottery-form-#{group.id}") do
      fill_in 'group_lottery_number', with: number.to_s
      find(:css, '#group_lottery_number').send_keys(:tab)
    end
  end

  def reload
    page.evaluate_script('window.location.reload()')
  end

  def lottery_number_saved?(_page, group, number)
    within("\#lottery-form-#{group.id}") do
      assert_selector(:css, "#group_lottery_number[value='#{number}']")
    end
  end
end
