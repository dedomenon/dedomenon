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

class CreateAccountTypes < ActiveRecord::Migration
  def self.up
    create_table :account_types, :force => true do |t|
        t.column :name,                          :text
        t.column :active,                        :boolean, :default => false
        t.column :free,                          :boolean, :default => false
        t.column :number_of_users,               :text,    :default => "madb_unlimited"
        t.column :number_of_databases,           :text,    :default => "1"
        t.column :monthly_fee,                   :float,   :default => 99.99
        t.column :maximum_file_size,             :integer, :default => 51200
        t.column :maximum_monthly_file_transfer, :integer, :default => 10485760, :limit => 8
        t.column :maximum_attachment_number,     :integer, :default => 50
    end

    AccountType.create( :id                             => 1,
                        :name                           => 'madb_account_type_free',
                        :active                         => 't',
                        :free                           => 't',
                        :number_of_users                => 'madb_unlimited',
                        :number_of_databases            => '1',
                        :monthly_fee                    => 0,
                        :maximum_file_size              => 51200,
                        :maximum_monthly_file_transfer  => 10485760,
                        :maximum_attachment_number      => 50
    )

    AccountType.create( :id                             => 2,
                        :name                           => 'madb_account_type_personal',
                        :active                         => 't',
                        :free                           => 'f',
                        :number_of_users                => 'madb_unlimited',
                        :number_of_databases            => '3',
                        :monthly_fee                    => 9.9,
                        :maximum_file_size              => 10485760,
                        :maximum_monthly_file_transfer  => 8589934592,
                        :maximum_attachment_number      => 200
    )

    ActiveRecord::Base.connection.execute("select setval('account_types_id_seq',2);")

  end


  def self.down
    drop_table :account_types
  end
end
