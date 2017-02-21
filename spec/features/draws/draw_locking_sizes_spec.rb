# frozen_string_literal: true
require 'rails_helper'

RSpec.feature 'Draw suite size locking' do
  before { log_in FactoryGirl.create(:admin) }
  let(:draw) do
    FactoryGirl.create(:draw).tap do |d|
      d.suites << Array.new(3) do |i|
        FactoryGirl.create(:suite_with_rooms, rooms_count: i + 1)
      end
      d.locked_sizes << 1
    end
  end

  it 'succeeds' do
    visit edit_draw_path(draw)
    check('Doubles')
    uncheck('Singles')
    click_on 'Save'
    expect(draw.reload.locked_sizes).to eq([2])
  end
end
