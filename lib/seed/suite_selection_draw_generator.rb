# frozen_string_literal: true

# Seed script generator for Draws
class SuiteSelectionDrawGenerator
  def self.generate(**overrides)
    new(overrides: overrides).generate
  end

  def initialize(overrides: {}); end

  def generate(overrides: {})
    LotteryDrawGenerator.generate(overrides: overrides).tap do |d|
      d.groups.each do |g|
        g.lottery_number = (g.id / 2).round
      end
      d.update(status: 'suite_selection')
    end
  end

end
