require_relative '../env'
require 'airrecord'
Airrecord.api_key = AIRTABLE_API_KEY 

module GigTableMeta
  TABLE = "Gig"
  ID = "id"
  GIG_NO = "Gig No"
  NIGHT_MANAGER = "Night Manager"
  VOL_1 = "Vol 1"
  VOL_2 = "Vol 2"
  ONLINE_TICKETS = "Online Tickets"
  TICKET_PRICE = "Ticket Price"
  WALK_INS = "Walk Ins"
  WALK_IN_SALES = "Walk In Sales"
  T_SHIRTS = "T Shirts"
  T_SHIRT_SALES = "T Shirt Sales"
  MUGS = "Mugs"
  MUG_SALES = "Mug Sales"
end

class GigTable < Airrecord::Table
  include GigTableMeta
  self.base_key = ALEX_VORTEX_DB_ID
  self.table_name = TABLE

end

