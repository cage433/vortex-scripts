require_relative '../env'
require 'kashflow'

def read_kashflow_receipts(start_page, end_page = nil)
  page = start_page
  client = Kashflow.client(KASHFLOW_USERNAME, KASHFLOW_PASSWORD)
  receipts = []
  in_progress = true
  while in_progress
    receipts += client.get_receipts_with_paging(:page => page, :per_page => 100)
    page += 1
    in_progress = receipts.length > 0
    unless end_page.nil?
      in_progress &= page <= end_page
    end
  end
  receipts
end
