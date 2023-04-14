require_relative '../controller/vol_rota_controller'
require_relative '../env.rb'
require_relative '../logging.rb'
require 'date'

airtable_events_personnel = VolunteerAirtableController.read_events_personnel(2023, 4)
