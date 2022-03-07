require_relative '../controller/vol_rota_controller'
require_relative '../env.rb'
require_relative '../logging.rb'


def sync_personnel_data(year, month, force = false)
  controller = VolRotaController.new()
  controller.update_vol_sheet_from_airtable(year, month, force)
  controller.update_airtable_from_vol_sheet(year, month, force)
end


VOL_ROTA_LOGGER.info("syncing data for #{VOL_ROTA_YEAR}/#{VOL_ROTA_MONTH}\n")
sync_personnel_data(VOL_ROTA_YEAR, VOL_ROTA_MONTH, force=false)
