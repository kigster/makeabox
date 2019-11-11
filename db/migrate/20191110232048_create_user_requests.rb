# frozen_string_literal: true

class CreateUserRequests < ActiveRecord::Migration[6.0]
  def change
    create_table :user_requests, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.belongs_to(:user, foreign_key: true, type: :uuid, null: false)
      t.string :state, null: false, default: 'new'
      t.timestamps null: false
    end
  end
end
