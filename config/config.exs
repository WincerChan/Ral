import Config

config :ral, :table,
  member: :ral_member,
  score: :ral_score

config :ral, :ral_rpc,
  # tcp or uds
  # config dir
  host: {127, 0, 0, 1},
  # file name
  addr: 7466
