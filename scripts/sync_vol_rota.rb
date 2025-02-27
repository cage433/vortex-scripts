require_relative '../controller/vol_rota_controller'
require_relative '../env.rb'
require_relative '../logging.rb'
require 'date'

def sync_personnel_data(year, month, force = false)
  controller = VolRotaController.new()
  controller.update_vol_sheet_from_airtable(year, month, force)
  controller.update_airtable_from_vol_sheet(year, month, force)
end

def log_status_on_sheet(message)
  update_time = DateTime.now.strftime("%Y-%m-%dT%H:%M:%S.%L")
  controller = VolRotaController.new.system_tab_controller
  controller.log_status(update_time, message)
end

def month_after(y, m)
  if m == 12
    [y + 1, 1]
  else
    [y, m + 1]
  end
end

today = Date.today
current_month = [today.year, today.month]
y1, m1 = [today.year, today.month]
y2, m2 = month_after(y1, m1)
y3, m3 = month_after(y2, m2)

begin
  [[y1, m1], [y2, m2], [y3, m3]].each { |y, m|
    LOG.info("syncing data for #{y}/#{m}\n")
    sync_personnel_data(y, m, force = false)
    LOG.info("Done")
  }
  log_status_on_sheet("No errors")
rescue => e
  log_status_on_sheet("Error: #{e}")
end
