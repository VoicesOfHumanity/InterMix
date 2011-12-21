# encoding: utf-8

# Import the text values for some arbitrary metatag

# ruby ./import_metatag.rb --metamap=2 --file=../../data/nationalities2.txt

require File.dirname(__FILE__)+'/cron_helper'
require 'optparse'

filename = ''
metamap_id = 0

opts = OptionParser.new
opts.on("-fARG","--file=ARG",String) {|val| filename = val}
opts.on("-mARG","--metamap=ARG",Integer) {|val| metamap_id = val}
opts.parse(ARGV)

if not filename or filename.to_s == ''
  puts '--file=filename please'
  exit
end
if not metamap_id or metamap_id.to_i == 0
  puts '--metamap=matamap_id please'
  exit
end

metamap = Metamap.find_by_id(metamap_id)
if not metamap
  puts "Unknown metamap"
  exit
end

if not File.exists?(filename)
  puts "File doesn't exist"
  exit
end

IO.foreach(filename) do |line|
  name = line.strip

  puts "#{name}"

  metamap_nodes = MetamapNode.where("metamap_id=? and name=?", metamap_id, name)
  if metamap_nodes.length == 0
    metamap_node = MetamapNode.create(:metamap_id=>metamap_id,:name=>name)
    puts "  added"
  end

end


