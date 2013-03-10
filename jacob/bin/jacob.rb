require_relative("../lib/jacob.rb")

unless ARGV.size != 3 then
  local_trends = TwitterConnector.new ARGV[0].to_f, ARGV[1].to_f, ARGV[2].to_f
  local_trends.getTrends
else
  puts "Invalid number of parameters, need Lat Lng Radius "
  exit 1
end

# 52.4744895, -1.4845575
