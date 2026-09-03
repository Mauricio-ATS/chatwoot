class CreateInternalMessageAttachments < ActiveRecord::Migration[7.2]
  def change
    create_table :internal_message_attachments do |t|
      t.bigint :internal_message_id, null: false
      t.bigint :account_id, null: false
      t.integer :file_type, null: false, default: 3
      t.string :extension

      t.timestamps
    end

    add_index :internal_message_attachments, :internal_message_id
    add_index :internal_message_attachments, :account_id

    add_foreign_key :internal_message_attachments,
                    :internal_messages

    add_foreign_key :internal_message_attachments,
                    :accounts
  end
end