class CreateInternalMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :internal_messages do |t|
      t.bigint :internal_conversation_id, null: false
      t.bigint :account_id, null: false
      t.bigint :user_id, null: false # autor da mensagem
      t.text :content
      t.integer :message_type, null: false, default: 0 # 0: text, 1: system (ex: "fulano entrou")

      t.timestamps
    end

    add_index :internal_messages, :internal_conversation_id
    add_index :internal_messages, :account_id
    add_index :internal_messages, :user_id
  end
end