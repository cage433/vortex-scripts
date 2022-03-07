require_relative '../controller/vol_rota_controller'

def sync_personnel_data(year, month, force = false)
  controller = VolRotaController.new()
  controller.update_vol_sheet_from_airtable(year, month, force)
  controller.update_airtable_from_vol_sheet(year, month, force)
end


sync_personnel_data(2022, 4, force=false)
