json.id internal_conversation.id
json.self_chat internal_conversation.self_chat
json.last_activity_at internal_conversation.last_activity_at
json.created_at internal_conversation.created_at
json.display_name internal_conversation.display_name(Current.user)

json.participants internal_conversation.participants do |user|
  json.id user.id
  json.name user.name
  json.email user.email
  json.avatar_url user.try(:avatar_url)
end

participant = internal_conversation.internal_conversation_participants.find_by(user_id: Current.user.id)
json.unread_count participant&.unread_count || 0