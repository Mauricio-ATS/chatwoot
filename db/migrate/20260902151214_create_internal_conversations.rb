class CreateInternalConversations < ActiveRecord::Migration[7.0]
  def change
    create_table :internal_conversations do |t|
      t.bigint :account_id, null: false
      t.bigint :created_by_id, null: false # user (agente) que iniciou a conversa
      t.boolean :self_chat, null: false, default: false # true quando é conversa consigo mesmo
      t.datetime :last_activity_at

      t.timestamps
    end

    add_index :internal_conversations, :account_id
    add_index :internal_conversations, :created_by_id
  end
end