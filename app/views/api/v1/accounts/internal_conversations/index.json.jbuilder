json.payload do
  json.array! @conversations, partial: 'internal_conversation', as: :internal_conversation
end