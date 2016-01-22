require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
#set :path, Rails.root
#set :output, 'log/cron.log'
env :PATH, ENV['PATH']

# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
#every 3.hours do
#  runner "MyModel.some_process"
#  rake "my:rake:task"
#  command "/usr/bin/my_great_command"
#end

#every 1.day, :at => '4:30 am' do
#  runner "MyModel.task_to_run_at_four_thirty_in_the_morning"
#end
#
#every :hour do # Many shortcuts available: :hour, :day, :month, :year, :reboot
#  runner "SomeModel.ladeeda"
#end
#
#every :sunday, :at => '12pm' do # Use any day of the week or :weekend, :weekday
#  runner "Task.do_something_great"
#end
#
#every '0 0 27-31 * *' do
#  command "echo 'you can use raw cron syntax too'"
#end

# Learn more: http://github.com/javan/whenever

every :day, :at => '06:00pm' do
  rake 'dmm:update_details'
end
