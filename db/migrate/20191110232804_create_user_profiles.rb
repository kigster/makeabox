# frozen_string_literal: true

class CreateUserProfiles < ActiveRecord::Migration[6.0]
  def change
    create_table 'user_profiles', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
      t.references :user, type: :uuid, null: false

      t.string :first_name
      t.string :last_name
      t.string :address
      t.string :country_code, length: 2
      t.string :state_or_provence
      t.string :phone

      t.timestamps
    end
  end
end
