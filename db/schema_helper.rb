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

# This class contains some methods that are invoked by the
# Schema::define() method in schema.rb.
# Authour:: Mohsin Hijazee
# Date:: 07 December 2007

#require File.dirname(__FILE__)+'/../vendor/plugins/ActiveRecordExtensions/lib/active_record_extensions.rb'

#require File.dirname(__FILE__) + '/../vendor/plugins/redhillonrails_core'
class SchemaHelperClass


  def load_fk_data()
    # Add your tables and relations here
    # This is a hash having each key an array as its value which in turn contains
    # reltationships. Each relationship is further a hash containing named paramerts of
    # the relationships.
    # This version is written manually.
    @relations = Hash.new

    @relations = {:account_type_values  =>
                [
                    {
                      :foreign_key      =>  :account_type_id,
                      :ref_table        =>  :account_types,
                      :ref_column       =>  :id
                    }
                ],

                   # Does not have any relations
                :account_types          => nil,

                :accounts               =>
                [
                    {
                      :foreign_key      =>  :account_type_id,
                      :ref_table        =>  :account_types,
                      :ref_column       =>  :id
                    }

                ],

                # Does not have any relations
                :data_types             => nil,

                :databases              =>
                [
                      {
                        :foreign_key     => :account_id,
                        :ref_table       => :accounts,
                        :ref_column      => :id
                      }
                ],


                :date_detail_values =>
                [
                      {
                        :foreign_key      =>  :detail_id,
                        :ref_table        =>  :details,
                        :ref_column       =>  :id
                      },

                      {
                        :foreign_key      =>  :instance_id,
                        :ref_table        =>  :instances,
                        :ref_column       =>  :id
                      }
                ],

                :ddl_detail_values =>
                [
                      {
                        :foreign_key      =>  :detail_id,
                        :ref_table        =>  :details,
                        :ref_column       =>  :id
                      },

                      {
                        :foreign_key      =>  :instance_id,
                        :ref_table        =>  :instances,
                        :ref_column       =>  :id
                      },

                      {
                        :foreign_key      =>  :detail_value_proposition_id,
                        :ref_table        =>  :detail_value_propositions,
                        :ref_column       =>  :id
                      }
                ],

                # Does not have any relations
                :detail_status => nil,

                :detail_value_propositions =>
                [
                      {
                        :foreign_key      =>  :detail_id,
                        :ref_table        =>  :details,
                        :ref_column       =>  :id
                      }
                ],

                :detail_values =>
                [
                      {
                        :foreign_key      =>  :detail_id,
                        :ref_table        =>  :details,
                        :ref_column       =>  :id
                      },

                      {
                        :foreign_key      =>  :instance_id,
                        :ref_table        =>  :instances,
                        :ref_column       =>  :id
                      }
                ],

                :details =>
                [
                      {
                        :foreign_key      =>  :data_type_id,
                        :ref_table        =>  :data_types,
                        :ref_column       =>  :id
                      },

                      {
                        :foreign_key      =>  :status_id,
                        :ref_table        =>  :detail_status,
                        :ref_column       =>  :id
                      },

                      {
                        :foreign_key      =>  :database_id,
                        :ref_table        =>  :databases,
                        :ref_column       =>  :id
                      }
                ],

                :entities =>
                [
                      {
                        :foreign_key      =>  :database_id,
                        :ref_table        =>  :databases,
                        :ref_column       =>  :id
                      }
                ],

                :entities2details =>
                [
                      {
                        :foreign_key      =>  :entity_id,
                        :ref_table        =>  :entities,
                        :ref_column       =>  :id
                      },

                      {
                        :foreign_key      =>  :detail_id,
                        :ref_table        =>  :details,
                        :ref_column       =>  :id
                      },

                      {
                        :foreign_key      =>  :status_id,
                        :ref_table        =>  :detail_status,
                        :ref_column       =>  :id
                      },


                ],

                :instances =>
                [
                      {
                        :foreign_key      =>  :entity_id,
                        :ref_table        =>  :entities,
                        :ref_column       =>  :id
                      },

                ],

                # Does not have underlying table
                :integer_detail_values =>
                [
                      {
                          :foreign_key    =>  :detail_id,
                          :ref_table      =>  :details,
                          :ref_column     =>  :id
                      },

                      {
                        :foreign_key      =>  :instance_id,
                        :ref_table        =>  :instances,
                        :ref_column       =>  :id
                      }
                ],

                :invoices =>
                [
                      {
                        :foreign_key      =>  :account_id,
                        :ref_table        =>  :accounts,
                        :ref_column       =>  :id
                      }

                ],

                :links =>
                [
                      {
                        :foreign_key      =>  :parent_id,
                        :ref_table        =>  :instances,
                        :ref_column       =>  :id
                      },

                      {
                        :foreign_key      =>  :child_id,
                        :ref_table        =>  :instances,
                        :ref_column       =>  :id
                      },

                      {
                        :foreign_key      =>  :relation_id,
                        :ref_table        =>  :relations,
                        :ref_column       =>  :id
                      }
                ],

                :paypay_communications =>
                [
                      {
                        :foreign_key      =>  :account_id,
                        :ref_table        =>  :accounts,
                        :ref_column       =>  :id
                      }
                ],

                :preferences =>
                [
                      {
                         :foreign_key     =>   :user_id,
                         :ref_table       =>   :users,
                         :ref_column      =>   :id
                      }
                ],

                #Does not have any relations
                :relation_side_types => nil,

                :relations =>
                [
                      {
                          :foreign_key      =>  :parent_id,
                          :ref_table        =>  :entities,
                          :ref_column       =>  :id
                      },

                      {
                          :foreign_key      =>  :child_id,
                          :ref_table        =>  :entities,
                          :ref_column       =>  :id
                      },

                      {
                          :foreign_key      =>  :parent_side_type_id,
                          :ref_table        =>  :relation_side_types,
                          :ref_column       =>  :id
                      },

                      {
                          :foreign_key      =>  :child_side_type_id,
                          :ref_table        =>  :relation_side_types,
                          :ref_column       =>  :id
                      }
                ],

                :transfers =>
                [
                      {
                          :foreign_key      =>  :account_id,
                          :ref_table        =>  :accounts,
                          :ref_column       =>  :id
                      },

                      {
                          :foreign_key      =>  :user_id,
                          :ref_table        =>  :users,
                          :ref_column       =>  :id
                      },

                      {
                          :foreign_key      =>  :detail_value_id,
                          :ref_table        =>  :detail_values,
                          :ref_column       =>  :id
                      },

                      {
                          :foreign_key      =>  :instance_id,
                          :ref_table        =>  :instances,
                          :ref_column       =>  :id
                      },

                      {
                          :foreign_key      =>  :entity_id,
                          :ref_table        =>  :entities,
                          :ref_column       =>  :id
                      }
                ],

                #Does not have any relationships
                :user_types => nil,

                :users =>
                [
                      {
                          :foreign_key      =>  :account_id,
                          :ref_table        =>  :accounts,
                          :ref_column       =>  :id
                      },

                      {
                          :foreign_key      =>  :user_type_id,
                          :ref_table        =>  :user_types,
                          :ref_column       =>  :id
                      }
                ]
              }

#  For table account_type_values

  end

  public
  def add_foreign_keys()


      @relations.each_key do |table|
        if @relations[table] != nil
          for relation in @relations[table]
            add_foreign_key table,
            relation[:foreign_key],
            relation[:ref_table],
            relation[:ref_column]
            #:name => "FK_#{relation[:foreign_key]}_OF_#{table}_REFERS_#{relation[:ref_column]}_IN_#{relation[:ref_table]}"
          end
        end
      end
    end

end