class CreateAccessTokens < ActiveRecord::Migration
  def self.up
    create_table :connect_access_tokens do |t|
      t.belongs_to :account, :client
      t.string :token
      t.datetime :expires_at
      t.timestamps
    end
    add_index :connect_access_tokens, :token, unique: true
  end

  def self.down
    drop_table :connect_access_tokens
  end
end
