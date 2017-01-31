# frozen_string_literal: true
require 'rails_helper'

RSpec.describe UserBuilder do
  describe '.build' do
    it 'calls :build on an instance of UserBuilder' do
      user_builder = mock_user_builder(id_attr: 'foo')
      described_class.build(id_attr: 'foo')
      expect(user_builder).to have_received(:build)
    end
  end

  describe '#build' do
    context 'success' do
      it 'returns instance of User class' do
        result = described_class.build(id_attr: 'foo')
        expect(result[:user]).to be_instance_of(User)
      end
      it 'returns unpersisted record' do
        result = described_class.build(id_attr: 'foo')
        expect(result[:user].persisted?).to be_falsey
      end
      it 'returns a success flash' do
        result = described_class.build(id_attr: 'foo')
        expect(result[:msg]).to have_key(:success)
      end
      it 'returns action: new' do
        result = described_class.build(id_attr: 'foo')
        expect(result[:action]).to eq('new')
      end
      context 'with CAS' do # rubocop:disable RSpec/NestedGroups
        before { allow(User).to receive(:cas_auth?).and_return(true) }
        it 'sets the username to the username' do
          result = described_class.build(id_attr: 'foo')
          expect(result[:user].username).to eq('foo')
        end
        it 'does not set the email' do
          result = described_class.build(id_attr: 'foo')
          expect(result[:user].email).to be_empty
        end
      end
      context 'without CAS' do # rubocop:disable RSpec/NestedGroups
        it 'sets the email to the username' do
          result = described_class.build(id_attr: 'foo')
          expect(result[:user].email).to eq('foo')
        end
      end
    end

    context 'failure' do
      context 'without CAS, taken email' do # rubocop:disable RSpec/NestedGroups
        it 'returns new instance of User' do
          allow(User).to receive(:where).with(email: 'foo')
            .and_return(instance_spy('ActiveRecord::Relation', count: 1))
          result = described_class.build(id_attr: 'foo')
          expect(result[:user].attributes).to eq(User.new.attributes)
        end
        it 'returns an error flash' do
          allow(User).to receive(:where).with(email: 'foo')
            .and_return(instance_spy('ActiveRecord::Relation', count: 1))
          result = described_class.build(id_attr: 'foo')
          expect(result[:msg]).to have_key(:error)
        end
        it 'returns action: build' do
          allow(User).to receive(:where).with(email: 'foo')
            .and_return(instance_spy('ActiveRecord::Relation', count: 1))
          result = described_class.build(id_attr: 'foo')
          expect(result[:action]).to eq('build')
        end
      end
    end
  end

  def mock_user_builder(params_hash)
    instance_spy('UserBuilder').tap do |user_builder|
      allow(UserBuilder).to receive(:new).with(params_hash)
        .and_return(user_builder)
    end
  end
end
