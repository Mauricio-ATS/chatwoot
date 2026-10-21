json.id internal_message.id
json.content internal_message.content
json.message_type internal_message.message_type
json.created_at internal_message.created_at
json.internal_conversation_id internal_message.internal_conversation_id

json.sender do
  json.id internal_message.user.id
  json.name internal_message.user.name
  json.avatar_url internal_message.user.try(:avatar_url)
end

json.attachments internal_message.internal_message_attachments.map(&:push_event_data)