# frozen_string_literal: true

FactoryBot.define do
  factory :draw do
    name 'MyString'
    active true

    factory :draw_with_members do
      transient do
        suites_count 1
        students_count 1
        groups_count 1
      end

      after(:create) do |draw, e|
        create_list(:suite_with_rooms, e.suites_count, draws: [draw])
        create_list(:student_in_draw, e.students_count, draw: draw)
      end

      factory :oversubscribed_draw do
        after(:create) do |draw, e|
          e.groups_count.times do
            l = create(:student_in_draw, draw: draw)
            create(:locked_group, size: 1, leader: l)
          end
          draw.suites.delete_all
          draw.update(status: 'group_formation')
        end
      end

      factory :draw_with_groups do
        after(:create) do |draw|
          create(:full_group, :defined_by_draw, draw: draw)
          create(:finalizing_group, :defined_by_draw, draw: draw)
          create(:locked_group, :defined_by_draw, draw: draw)
          create(:open_group, :defined_by_draw, draw: draw)
        end
      end

      factory :draw_in_lottery do
        after(:create) do |draw, e|
          suites = create_list(:suite_with_rooms, e.groups_count, draws: [draw])
          suites.each do |suite|
            l = create(:student_in_draw, draw: draw)
            create(:locked_group, size: suite.size, leader: l)
          end
          # clean-up to ensure we only have valid students
          draw.draw_memberships.each do |s|
            unless s.off_campus? || (s.on_campus? && s.group.present?)
              s.destroy!
            end
          end
          draw.update(status: 'lottery')
        end
      end

      factory :draw_in_selection do
        after(:create) do |draw, e|
          suites = create_list(:suite_with_rooms, e.groups_count, draws: [draw])
          # clean-up to ensure we only have valid students
          draw.draw_memberships.each do |s|
            unless s.off_campus? || (s.on_campus? && s.group.present?)
              s.destroy!
            end
          end
          draw.update(status: 'lottery')
          suites.each do |suite|
            l = create(:student_in_draw, draw: draw)
            g = create(:locked_group, size: suite.size, leader: l)
            create(:lottery_assignment, :defined_by_group, group: g)
          end
          draw.update(status: 'suite_selection')
        end
      end
    end
  end
end
