# frozen_string_literal: true

class EnableExtensions < ActiveRecord::Migration[6.0]
  def up
    enable_extension 'plpgsql'
    enable_extension 'uuid-ossp'
    enable_extension 'pgcrypto'
  end

  def down
    disable_extension 'pgcrypto'
    disable_extension 'uuid-ossp'
    disable_extension 'plpgsql'
  end
end
