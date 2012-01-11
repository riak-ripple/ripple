# You MUST add models to this file, in the correct order by
# dependency (no deps at top).  There is no auto-require.
%w[
  note
  page
  box
  car
  clock
  customer
  email
  family
  favorite
  subscription
  team
  transactions
  tree
  widget
  address
  cardboard_box
  clock_observer
  invoice
  paid_invoice
  late_invoice
  company
  profile
  user
  ninja
  tasks
  credit_card
  post
  nested
  indexer
  ].each do |file|
  require File.join("support", "models", file)
end
