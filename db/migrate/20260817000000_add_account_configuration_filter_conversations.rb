class AddAccountConfigurationFilterConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts,
           :agents_can_only_see_assigned_conversations,
           :boolean,
           default: false,
           null: false
  end
end
