# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

religions = Religion.create([
  {name: "African Traditional", shortname: "AfricanTrad", subdiv: "trad"},
  {name: "Agnostic", shortname: "Agnostic", subdiv: "nodenom"},
  {name: "Atheist", shortname: "Atheist", subdiv: "nodenom"},
  {name: "Baha’i", shortname: "Bahai", subdiv: "nodenom"},
  {name: "Buddhism", shortname: "Buddhism", subdiv: "denom"},
  {name: "Caodaism", shortname: "Caodaism", subdiv: "denom"},
  {name: "Chinese Traditional", shortname: "ChineseTrad", subdiv: "trad"},
  {name: "Christianity", shortname: "Christianity", subdiv: "denom"},
  {name: "Hinduism", shortname: "Hinduism", subdiv: "denom"},
  {name: "Indigenous", shortname: "IndigenousRel", subdiv: "people"},
  {name: "Islam", shortname: "Islam", subdiv: "denom"},
  {name: "Jainism", shortname: "Jainism", subdiv: "denom"},
  {name: "Judaism", shortname: "Judaism", subdiv: "denom"},
  {name: "Paganism", shortname: "Paganism", subdiv: "path"},
  {name: "Rastafari", shortname: "Rastafari", subdiv: "denom"},
  {name: "Shinto", shortname: "Shinto", subdiv: "denom"},
  {name: "Sikhism", shortname: "Sikhism", subdiv: "denom"},
  {name: "Spiritism", shortname: "Spiritism", subdiv: "nodenom"},
  {name: "Spiritual", shortname: "Spiritual", subdiv: "path"},
  {name: "Tenrikyo", shortname: "Tenrikyo", subdiv: "nodenom"},
  {name: "Unaffiliated", shortname: "Unaffiliated", subdiv: "nodenom"},
  {name: "Unitarian Universalism", shortname: "UnitarianU", subdiv: "nodenom"},
  {name: "Other", shortname: "OtherReligion", subdiv: "name"}
])
