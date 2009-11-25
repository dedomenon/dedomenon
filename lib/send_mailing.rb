################################################################################
#This file is part of Dedomenon.
#
#Dedomenon is free software: you can redistribute it and/or modify
#it under the terms of the GNU Affero General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#Dedomenon is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU Affero General Public License for more details.
#
#You should have received a copy of the GNU Affero General Public License
#along with Dedomenon.  If not, see <http://www.gnu.org/licenses/>.
#
#Copyright 2008 Raphaël Bauduin
################################################################################

require 'net/smtp'
require 'enumerator'
require 'breakpoint'

#number of mails sent in one connection to the smtp server
SENDING_BATCH_SIZE=50


tmail = Mailings.create_mailing()

users = User.find(:all, :conditions => "verified=1")
recipients = users.collect{|u| u.login} 

#uncomment this for testing
#recipients = ["raphinou@yahoo.com","rb@raphinou.com"]


puts "Are you sure you want to send the mailing to #{recipients.length} recipients? Type yes to confirm."
confirmation = (STDIN.readline.chop=='yes')
exit if !confirmation
puts "sending...."

exceptions = {}
recipients.each_slice(SENDING_BATCH_SIZE) do |recipients_slice|
  Net::SMTP.start('localhost', 25) do |sender|
    recipients_slice.each do |recipient|
      tmail.to = recipient
      begin
        sender.sendmail tmail.encoded, tmail.from, recipient
      rescue Exception => e
        exceptions[recipient] = e 
        #needed as the next mail will send command MAIL FROM, which would 
        #raise a 503 error: "Sender already given"
        sender.finish
        sender.start
      end
    end
  end
end

if exceptions.length>0
  answer = ""
  while not ["y","n"].include? answer
    puts "There were #{exceptions.length} errors! Do you want to use breakpoint to see them? (y/n)"
    answer = STDIN.readline.chop
  end
  breakpoint if (answer=='y')
  logfile = "log/mailing-exceptions-#{Time.now.strftime("%Y-%m-%dT%H:%M:%S")}.yaml"
  File.open( logfile, 'w' ) do |out| YAML.dump( exceptions, out ) end
  puts "You can find a dump of the exceptions in #{logfile}"
end
