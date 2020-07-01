import Config

config :ral,
  # 漏斗容量： 30
  total: 30,
  # 恢复速率：10s/个
  speed: 0.1,
  member: :ral_member,
  score: :ral_score
