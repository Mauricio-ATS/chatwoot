class CreateInternalConversationParticipants < ActiveRecord::Migration[7.0]
  def change
    create_table :internal_conversation_participants do |t|
      t.bigint :internal_conversation_id, null: false
      t.bigint :user_id, null: false
      t.bigint :account_id, null: false
      t.datetime :last_read_at # controla mensagens não lidas por participante

      t.timestamps
    end

    add_index :internal_conversation_participants, :internal_conversation_id, name: 'idx_int_conv_participants_conversation'
    add_index :internal_conversation_participants, :user_id
    add_index :internal_conversation_participants, [:internal_conversation_id, :user_id],
              unique: true, name: 'idx_int_conv_participants_unique'
  end
end