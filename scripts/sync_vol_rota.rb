require_relative '../controller/vol_rota_controller'
require_relative '../env.rb'
require_relative '../logging.rb'
require 'date'


def sync_personnel_data(year, month, force = false)
  controller = VolRotaController.new()
  controller.update_vol_sheet_from_airtable(year, month, force)
  controller.update_airtable_from_vol_sheet(year, month, force)
end


today = Date.today
current_month = [today.year, today.month]
next_month = if today.month == 12
               [today.year + 1, 1]
             else
               [today.year, today.month + 1]
             end

[current_month, next_month].each { |y, m|
  VOL_ROTA_LOGGER.info("syncing data for #{y}/#{m}\n")
  sync_personnel_data(y, m, force=false)

}
