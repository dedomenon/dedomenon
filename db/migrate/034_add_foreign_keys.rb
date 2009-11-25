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

class AddForeignKeys < ActiveRecord::Migration

  # PENDING do not call the add_foreign_key method instead execuate quries.
  # PENDING database would delete: details, entities, detail_values
  # PENDING prepare a full map.
  def self.load_fk_data()
    # Add your tables and relations here
    # This is a hash having each key an array as its value which in turn contains
    # reltationships. Each relationship is further a hash containing named paramerts of
    # the relationships.
    # This version is written manually.
    @@relations = Hash.new

    @@relations = {:account_type_values  =>
                [
                    {
                      :foreign_key      =>  :account_type_id,
                      :ref_table        =>  :account_types,
                      :ref_column       =>  :id,
                      :on_delete        =>  :cascade
                    }
                ],

                   # Does not have any relations
                :account_types          => nil,

                :accounts               =>
                [
                    {
                      :foreign_key      =>  :account_type_id,
                      :ref_table        =>  :account_types,
                      :ref_column       =>  :id,
                      :on_delete        =>  :cascade
                    }

                ],

                # Does not have any relations
                :data_types             => nil,

                :databases              =>
                [
                      {
                        :foreign_key     => :account_id,
                        :ref_table       => :accounts,
                        :ref_column      => :id,
                        :on_delete       => :cascade
                      }
                ],


                :date_detail_values =>
                [
                      {
                        :foreign_key      =>  :detail_id,
                        :ref_table        =>  :details,
                        :ref_column       =>  :id,
                        :on_delete        =>  :cascade
                      },

                      {
                        :foreign_key      =>  :instance_id,
                        :ref_table        =>  :instances,
                        :ref_column       =>  :id,
                        :on_delete        =>  :cascade
                      }
                ],

                :ddl_detail_values =>
                [
                      {
                        :foreign_key      =>  :detail_id,
                        :ref_table        =>  :details,
                        :ref_column       =>  :id,
                        :on_delete        =>  :cascade
                      },

                      {
                        :foreign_key      =>  :instance_id,
                        :ref_table        =>  :instances,
                        :ref_column       =>  :id,
                        :on_delete        =>  :cascade
                      },

                      {
                        :foreign_key      =>  :detail_value_proposition_id,
                        :ref_table        =>  :detail_value_propositions,
                        :ref_column       =>  :id,
                        :on_delete        =>  :cascade
                      }
                ],

                # Does not have any relations
                :detail_status => nil,

                :detail_value_propositions =>
                [
                      {
                        :foreign_key      =>  :detail_id,
                        :ref_table        =>  :details,
                        :ref_column       =>  :id,
                        :on_delete        =>  :cascade
                      }
                ],

                :detail_values =>
                [
                      {
                        :foreign_key      =>  :detail_id,
                        :ref_table        =>  :details,
                        :ref_column       =>  :id,
                        :on_delete        => :cascade
                      },

                      {
                        :foreign_key      =>  :instance_id,
                        :ref_table        =>  :instances,
                        :ref_column       =>  :id,
                        :on_delete        => :cascade
                      }
                ],

                :details =>
                [
                      {
                        :foreign_key      =>  :data_type_id,
                        :ref_table        =>  :data_types,
                        :ref_column       =>  :id,
                        :on_delete        => :cascade
                      },

                      # WARNING! If a detail_status is deleted, we do not
                      # delete the corresponding details
                      {
                        :foreign_key      =>  :status_id,
                        :ref_table        =>  :detail_status,
                        :ref_column       =>  :id,
                        :on_delete        => :set_default
                      },

                      {
                        :foreign_key      =>  :database_id,
                        :ref_table        =>  :databases,
                        :ref_column       =>  :id,
                        :on_delete        =>  :cascade
                      }
                ],

                :entities =>
                [
                      {
                        :foreign_key      =>  :database_id,
                        :ref_table        =>  :databases,
                        :ref_column       =>  :id,
                        :on_delete        =>  :cascade
                      }
                ],

                :entities2details =>
                [
                      {
                        :foreign_key      =>  :entity_id,
                        :ref_table        =>  :entities,
                        :ref_column       =>  :id,
                        :on_delete        =>  :cascade
                      },

                      {
                        :foreign_key      =>  :detail_id,
                        :ref_table        =>  :details,
                        :ref_column       =>  :id,
                        :on_delete        =>  :cascade
                      },

                      # WARNING! If a detail_status is deleted, we do not
                      # delete its entities2details links!
                      {
                        :foreign_key      =>  :status_id,
                        :ref_table        =>  :detail_status,
                        :ref_column       =>  :id,
                        :on_delete        =>  :set_default
                      },


                ],

                :instances =>
                [
                      {
                        :foreign_key      =>  :entity_id,
                        :ref_table        =>  :entities,
                        :ref_column       =>  :id,
                        :on_delete        =>  :cascade
                      },

                ],


                :integer_detail_values =>
                [
                      {
                          :foreign_key    =>  :detail_id,
                          :ref_table      =>  :details,
                          :ref_column     =>  :id,
                          :on_delete      =>  :cascade
                      },

                      {
                        :foreign_key      =>  :instance_id,
                        :ref_table        =>  :instances,
                        :ref_column       =>  :id,
                        :on_delete        =>  :cascade
                      }
                ],

# This key will not be created as its being done in paypal plugin.
#                :invoices =>
#                [
#                      {
#                        :foreign_key      =>  :account_id,
#                        :ref_table        =>  :accounts,
#                        :ref_column       =>  :id,
#                        :on_delete        =>  :cascade
#                      }
#
#                ],

                :links =>
                [
                      {
                        :foreign_key      =>  :parent_id,
                        :ref_table        =>  :instances,
                        :ref_column       =>  :id,
                        :on_delete        =>  :cascade
                      },

                      {
                        :foreign_key      =>  :child_id,
                        :ref_table        =>  :instances,
                        :ref_column       =>  :id,
                        :on_delete        =>  :cascade
                      },

                      {
                        :foreign_key      =>  :relation_id,
                        :ref_table        =>  :relations,
                        :ref_column       =>  :id,
                        :on_delete        =>  :cascade
                      }
                ],

# These relationships are also disbaled for now.
#                :paypal_communications =>
#                [
#                      {
#                        :foreign_key      =>  :account_id,
#                        :ref_table        =>  :accounts,
#                        :ref_column       =>  :id,
#                        :on_delete        =>  :cascade
#                      }
#                ],

                :preferences =>
                [
                      {
                         :foreign_key     =>   :user_id,
                         :ref_table       =>   :users,
                         :ref_column      =>   :id,
                         :on_delete       =>  :cascade
                      }
                ],

                #Does not have any relations
                :relation_side_types => nil,

                :relations =>
                [
                      {
                          :foreign_key      =>  :parent_id,
                          :ref_table        =>  :entities,
                          :ref_column       =>  :id,
                          :on_delete        =>  :cascade
                      },

                      {
                          :foreign_key      =>  :child_id,
                          :ref_table        =>  :entities,
                          :ref_column       =>  :id,
                          :on_delete        =>  :cascade
                      },

                      {
                          :foreign_key      =>  :parent_side_type_id,
                          :ref_table        =>  :relation_side_types,
                          :ref_column       =>  :id,
                          :on_delete        =>  :cascade
                      },

                      {
                          :foreign_key      =>  :child_side_type_id,
                          :ref_table        =>  :relation_side_types,
                          :ref_column       =>  :id,
                          :on_delete        =>  :cascade
                      }
                ],

# We comment this out because this table might not be in futrue.
#                :transfers =>
#                [
#                      {
#                          :foreign_key      =>  :account_id,
#                          :ref_table        =>  :accounts,
#                          :ref_column       =>  :id,
#                          :on_delete        =>  :cascade
#                      },
#
#                      # WARNING! Deleting a user will not delete the transfers!
#                      {
#                          :foreign_key      =>  :user_id,
#                          :ref_table        =>  :users,
#                          :ref_column       =>  :id,
#                          :on_delete        =>  :set_default
#                      },
#
#                      # WARNING! Same as above
#                      {
#                          :foreign_key      =>  :detail_value_id,
#                          :ref_table        =>  :detail_values,
#                          :ref_column       =>  :id,
#                          :on_delete        =>  :set_default
#                      },
#
#                      {
#                          :foreign_key      =>  :instance_id,
#                          :ref_table        =>  :instances,
#                          :ref_column       =>  :id,
#                          :on_delete        =>  :set_default
#                      },
#
#                      {
#                          :foreign_key      =>  :entity_id,
#                          :ref_table        =>  :entities,
#                          :ref_column       =>  :id,
#                          :on_delete        =>  :set_default
#                      }
#                ],

                #Does not have any relationships
                :user_types => nil,

                :users =>
                [
                      {
                          :foreign_key      =>  :account_id,
                          :ref_table        =>  :accounts,
                          :ref_column       =>  :id,
                          :on_delete        =>  :cascade
                      },

                      {
                          :foreign_key      =>  :user_type_id,
                          :ref_table        =>  :user_types,
                          :ref_column       =>  :id,
                          :on_delete        =>  :cascade
                      }
                ]
              }

#  For table account_type_values

  end


  def self.add_foreign_keys()


      @@relations.each_key do |table|
        if @@relations[table] != nil
          for relation in @@relations[table]
#            add_foreign_key table,
#            relation[:foreign_key],
#            relation[:ref_table],
#            relation[:ref_column],
#            :on_delete => relation[:on_delete]

            add_FK  :table => table,
                    :foreign_key => relation[:foreign_key],
                    :ref_table => relation[:ref_table],
                    :ref_column => relation[:ref_column],
                    :on_delete => relation[:on_delete]
            #:name => "FK_#{relation[:foreign_key]}_OF_#{table}_REFERS_#{relation[:ref_column]}_IN_#{relation[:ref_table]}"
          end
        end
      end
    end

  def self.remove_foreign_keys()
    @@relations.each_key do |table|
        if @@relations[table] != nil
          for relation in @@relations[table]
            begin
#              remove_foreign_key table,
#              "#{table.to_s}_#{relation[:foreign_key].to_s}_fkey"
               remove_FK  :table => table, 
                          :foreign_key => relation[:foreign_key].to_s
            rescue RuntimeError
              print "#{table.to_s}_#{relation[:foreign_key].to_s}_fkey" +
                    "does not exists.\n"
            end
          end
        end
      end
  end


  def self.add_FK(fkData = {
                    :table => "",           # The table that has foreiegn key
                    :foreign_key => "",     # column that is foreign key in that table
                    :ref_table => "",       # Refers what table?
                    :ref_column => "",       # And what column>
                    :on_update => :no_action,
                    :on_delete => :no_action

    })

    # if any parameter missing, return at once!
    if fkData[:table] == "" or
       fkData[:foreign_key] == "" or
       fkData[:ref_table] == "" or
       fkData[:ref_column] == "" then
        return
    end

    table = fkData[:table].to_s
    foreign_key = fkData[:foreign_key].to_s
    ref_table = fkData[:ref_table].to_s
    ref_column = fkData[:ref_column].to_s
    constraint_name = table + "_" + foreign_key + "_fkey"
    on_update = fkData[:on_update].to_s.gsub(/_/, ' ').upcase
    on_delete = fkData[:on_delete].to_s.gsub(/_/, ' ').upcase
    
    #puts on_update + "    " + on_delete
    
    on_update = "SET DEFAULT" if on_update == ""
    on_delete = "SET DEFAULT" if on_delete == ""
    
    sql = %Q/ALTER TABLE #{table}
  ADD CONSTRAINT #{constraint_name} FOREIGN KEY (#{foreign_key})
      REFERENCES #{ref_table} (#{ref_column}) MATCH SIMPLE
      ON UPDATE #{on_update} ON DELETE #{on_delete};/
    
    #puts sql
    db = ActiveRecord::Base.connection()
    
    db.execute(sql)

  end
  
  def self.remove_FK(fkData = {
                    :table => "",           # The table that has foreiegn key
                    :foreign_key => "",     # column that is foreign key in that table
#                    :ref_table => "",       # Refers what table?
#                    :ref_column => ""       # And what column>
                    })
                  
    table = fkData[:table].to_s
    foreign_key = fkData[:foreign_key].to_s
    
    
    constraint_name = table + "_" + foreign_key + "_fkey"
    
    db = ActiveRecord::Base.connection()
    
    sql = %Q/ALTER TABLE #{table} DROP CONSTRAINT #{constraint_name}/
    
    db.execute(sql)
    
  end

  def self.up
    load_fk_data()
    add_foreign_keys()
  end

  def self.down
    load_fk_data()
    remove_foreign_keys
  end
end
