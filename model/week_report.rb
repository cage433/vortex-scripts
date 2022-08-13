class WeekReport
  def initialize(
    week:,
    audience_number:,
    advance_ticket_sales:,
    card_ticket_sales:,
    cash_ticket_sales:
  )
    @week = week
    @audience_number = audience_number
    @advance_ticket_sales = advance_ticket_sales
    @card_ticket_sales = card_ticket_sales
    @cash_ticket_sales = cash_ticket_sales
  end
end
