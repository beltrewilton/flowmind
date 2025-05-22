 Postgrex.Types.define(
   Flowmind.PostgresTypes,
   [Pgvector.Extensions.Vector] ++ Ecto.Adapters.Postgres.extensions(),
   []
 )