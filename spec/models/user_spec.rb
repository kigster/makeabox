# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string
#  failed_attempts        :integer          default(0), not null
#  unlock_token           :string
#  locked_at              :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#


require 'rails_helper'

RSpec.describe User, type: :model do

  let(:bobbys_email_address) { 'bob@test.com' }

  subject(:bob) { build :user,
                        email:    bobbys_email_address,
                        username: 'bobbyboy' }

  context 'user is valid when' do
    its(:email) { should eq bobbys_email_address }
    its(:valid?) { should be_truthy }
  end

  context 'find this user' do
    it 'should be our bob' do
      User.transaction do
        bob.save!
        bobby = User.where(email: bobbys_email_address).first
        expect(bobby).to eq(bob)
        raise ActiveRecord::Rollback
      end
    end
  end
end
