#-- period_results.rb ---- Calculate top results for each discussion period

require File.dirname(__FILE__)+'/cron_helper'

@metamaps = Metamap.where(:id=>[3,5])

app = ActionDispatch::Integration::Session.new(Rails.application)

periods = Period.where(nil)

for period in periods
  
  next if not period.dialog
  
  puts "Period:#{period.id} #{period.period_number.to_i > 0 ? "##{period.period_number} " : ""}#{period.startdate} Name:#{period.name} Discussion:#{period.dialog_id}:#{period.dialog.name}"

  @data = {}
  result = {}
  
  #-- Get the HTML that will be shown above forum item listings. For each type of crosstalk

  puts "  getting gender results"
  app.get "/dialogs/#{period.dialog_id}/previous_result?period_id=#{period.id}&crosstalk=gender"
  result['gender'] = app.response.body

  puts "  getting age results"
  app.get "/dialogs/#{period.dialog_id}/previous_result?period_id=#{period.id}&crosstalk=age"
  result['age'] = app.response.body

  period.result_will_change!
  period.result = result
  period.save!
  
end

