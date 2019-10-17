# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Draw group report' do
  include GroupsHelper # for status-displaying

  let!(:draw) { create(:draw, status: 'group_formation') }
  let!(:groups) { create_groups(draw: draw, statuses: %w(full open locked)) }

  context 'navigation' do
    before { log_in create(:admin) }
    it 'navigates to view from dashboard' do
      visit root_path
      first(:link, draw.name).click
      click_on 'View printable group report'
      expect(page).to have_content('All Groups')
    end
  end

  context 'as admin' do
    before { log_in create(:admin) }
    it 'displays a table with edit links for all groups' do
      visit draw_path(draw)
      groups.each do |group|
        expect(page_has_group_report(page: page, group: group, edit: true)).to \
          be_truthy
      end
    end
  end

  context 'as leader' do
    let(:user) { groups.first.leader }

    before { log_in user }
    it 'displays a table with only the appropriate button' do
      visit draw_path(draw)
      groups.each do |group|
        expect(page_has_group_report(page: page, group: group,
                                     edit: user.leader_of?(group))).to be_truthy
      end
    end
  end

  context 'printable report' do
    before { log_in create(:student, role: 'rep') }

    it 'can be viewed by reps' do
      visit draw_path(draw)
      click_on 'View printable group report'
      expect(page).to have_css('td[data-role="group-members"]')
    end
  end

  def page_has_group_report(page:, group:, edit: false)
    edit_assert_method = edit ? :assert_selector : :assert_no_selector
    status_text = display_group_status(group)
    within(".group-report tr#group-#{group.id}") do
      page.assert_selector(:css, 'th[data-role="group-leader"]',
                           text: group.leader.full_name) &&
        page.assert_selector(:css, 'td[data-role="group-status"]',
                             text: status_text) &&
        page.send(edit_assert_method, :css, 'a.button', text: 'Edit')
    end
  end

  def create_groups(draw:, statuses:)
    statuses.map do |status|
      factory = "#{status}_group".to_sym
      leader = create(:student_in_draw, draw: draw)
      create(factory, leader: leader)
    end
  end
end
