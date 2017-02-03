# frozen_string_literal: true
# Seed script generator for Users
class UserGenerator
  def self.generate(**overrides)
    new(overrides: overrides).generate
  end

  def self.generate_admin(**overrides)
    new(overrides: overrides.merge(role: 'admin')).generate
  end

  def initialize(overrides: {})
    gen_params(overrides: overrides)
    @params.delete(:password) if User.cas_auth?
  end

  def generate
    Creator.new(klass: User, params: params,
                name_method: :name).create![:object]
  end

  private

  attr_reader :params

  def gen_params(overrides: {})
    @params ||= { first_name: FFaker::Name.first_name,
                  last_name: FFaker::Name.last_name,
                  email: FFaker::Internet.email,
                  gender: User.genders.keys.sample,
                  role: 'student',
                  intent: User.intents.keys.sample,
                  password: 'passw0rd',
                  class_year: random_class_year,
                  college: random_college_str }.merge(overrides)
  end

  def random_class_year
    Time.zone.today.year + (1..3).to_a.sample
  end

  def random_college_str
    ('A'..'Z').to_a.sample(2).join
  end
end
