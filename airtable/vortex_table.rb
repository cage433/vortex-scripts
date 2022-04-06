require 'airrecord'

def select_with_date_filter(
  table:, fields:, date_field:, first_date:, last_date:, extra_filters: [], view_name: nil)

  # Necessary evil to deal with timezone issue I've not gotten to the bottom of
  day_before_first_text = (first_date - 1).strftime("%Y-%m-%d")
  day_after_last_text = (last_date + 1).strftime("%Y-%m-%d")
  filters = extra_filters + 
    [
      "{#{date_field}} > '#{day_before_first_text}'", 
      "{#{date_field}} < '#{day_after_last_text}'"
    ] 
  filter_text = "And(" + filters.join(", ") + ")"

  if !fields.nil? && !fields.include?(date_field)
    fields = fields.push(date_field)
  end

  all(
    fields: fields,
    filter: filter_text,
    view: view_name
  ).filter { |rec|
    parsed_date = Date.parse(rec[date_field]) 
    first_date <= parsed_date && parsed_date <= last_date
  }

end


