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

require 'pathname'

class SystemNotifier < ActionMailer::Base
  SYSTEM_EMAIL_ADDRESS = AppConfig.system_email_address
  EXCEPTION_RECIPIENT = AppConfig.exception_recipients

  def exception_notification(controller, request, exception, sent_on = Time.now)
    @subject = sprintf("[ERROR] %s\#%s  (%s) %s",
                      controller.controller_name,
                        controller.action_name,
                        exception.class,
                        exception.message.inspect)
    @body = { "controller" => controller, "request" => request, "exception" => exception, "backtrace" => sanitize_backtrace( exception.backtrace), "host" => request.env["HTTP_HOST"], "rails_root" => RAILS_ROOT}
    @sent_on = sent_on
    @from = SYSTEM_EMAIL_ADDRESS
    @recipients = EXCEPTION_RECIPIENT
  end

  def translation_problem_notification(controller, request, exception, params, sent_on = Time.now)
    @subject = sprintf("[TRANSLATION] %s (%s) %s\#%s  (%s) ",
                      params[:t_id],
                      params[:lang],
                      controller.controller_name,
                      controller.action_name,
                      exception.class)
    @body = { "controller" => controller, "request" => controller.request, "exception" => exception, "backtrace" => sanitize_backtrace( exception.backtrace), "host" => controller.request.env["HTTP_HOST"], "rails_root" => RAILS_ROOT, "msg_params" => params  }
    @sent_on = sent_on
    @from = SYSTEM_EMAIL_ADDRESS
    @recipients = EXCEPTION_RECIPIENT
  end

  def authentication_refused(controller, request, login, sent_on = Time.now)
    @subject = sprintf("[AUTHENTICATION ERROR] for %s", login)
    user = User.find_by_login(login)
    account = user.account
    @body = { "controller" => controller, "request" => request, "modb_user" => user, "account" => account,  "host" => request.env["HTTP_HOST"], "rails_root" => RAILS_ROOT}
    @sent_on = sent_on
    @from = SYSTEM_EMAIL_ADDRESS
    @recipients = EXCEPTION_RECIPIENT
  end

  def paypal_problem_notification( request, pdt, message , sent_on = Time.now)
    @subject = sprintf("[PAYPAL ERROR] account %s", pdt.item_number)
    @body = { "request" => request, "pdt" => pdt, "message" => message }
    @sent_on = sent_on
    @from = SYSTEM_EMAIL_ADDRESS
    @recipients = EXCEPTION_RECIPIENT
  end

  def paypal_problem_ipn( request, ipn, message , sent_on = Time.now)
    @subject = sprintf("[PAYPAL ERROR] account id %s", ipn.params["item_number"])
    @body = { "request" => request, "ipn" => ipn, "message" => message }
    @sent_on = sent_on
    @from = SYSTEM_EMAIL_ADDRESS
    @recipients = EXCEPTION_RECIPIENT
  end
  private

  def sanitize_backtrace(trace)
    re = Regexp.new(/^#{Regexp.escape(RAILS_ROOT)}/)
    trace.map do |line|
        Pathname.new(line.gsub(re,"[RAILS_ROOT]")).cleanpath.to_s
    end
  end
  
end

