# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090326101723) do

  create_table "account_type_values", :force => true do |t|
    t.integer "account_type_id"
    t.text    "detail"
    t.text    "value"
  end

  create_table "account_types", :force => true do |t|
    t.text    "name"
    t.boolean "active",                                     :default => false
    t.boolean "free",                                       :default => false
    t.text    "number_of_users",                            :default => "madb_unlimited"
    t.text    "number_of_databases",                        :default => "1"
    t.float   "monthly_fee",                                :default => 99.99
    t.integer "maximum_file_size",                          :default => 51200
    t.integer "maximum_monthly_file_transfer", :limit => 8, :default => 10485760
    t.integer "maximum_attachment_number",                  :default => 50
  end

  create_table "accounts", :force => true do |t|
    t.integer "account_type_id"
    t.text    "name",                                         :null => false
    t.text    "street"
    t.text    "zip_code"
    t.text    "city"
    t.text    "country"
    t.text    "status",               :default => "inactive"
    t.date    "end_date"
    t.text    "subscription_id"
    t.text    "subscription_gateway"
    t.text    "vat_number"
    t.integer "attachment_count",     :default => 0
    t.integer "lock_version",         :default => 0
  end

  create_table "data_types", :force => true do |t|
    t.text "name"
    t.text "class_name"
  end

  create_table "databases", :force => true do |t|
    t.integer "account_id",                  :null => false
    t.text    "name"
    t.integer "lock_version", :default => 0
  end

  create_table "date_detail_values", :force => true do |t|
    t.integer  "detail_id"
    t.integer  "instance_id"
    t.datetime "value"
    t.integer  "lock_version", :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "date_detail_values", ["detail_id"], :name => "i_date_detail_value__detail_id"
  add_index "date_detail_values", ["instance_id"], :name => "i_date_detail_value__instance_id"

  create_table "ddl_detail_values", :force => true do |t|
    t.integer  "detail_id"
    t.integer  "instance_id"
    t.integer  "detail_value_proposition_id"
    t.integer  "lock_version",                :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ddl_detail_values", ["detail_id"], :name => "i_ddl_detail_value__detail_id"
  add_index "ddl_detail_values", ["instance_id"], :name => "i_ddl_detail_value__instance_id"

  create_table "detail_status", :force => true do |t|
    t.text "name"
  end

  create_table "detail_value_propositions", :force => true do |t|
    t.integer "detail_id"
    t.text    "value"
    t.integer "lock_version", :default => 0
  end

  create_table "detail_values", :force => true do |t|
    t.integer  "detail_id"
    t.integer  "instance_id"
    t.text     "value"
    t.text     "type"
    t.integer  "lock_version", :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "detail_values", ["detail_id"], :name => "i_detail_value__detail_id"
  add_index "detail_values", ["instance_id"], :name => "i_detail_value__instance_id"

  create_table "details", :force => true do |t|
    t.text    "name"
    t.integer "data_type_id"
    t.integer "status_id"
    t.integer "database_id"
    t.integer "lock_version", :default => 0
  end

  create_table "entities", :force => true do |t|
    t.integer "database_id",                        :null => false
    t.text    "name"
    t.boolean "has_public_form", :default => false
    t.integer "lock_version",    :default => 0
    t.boolean "has_public_data", :default => false
    t.boolean "public_to_all",   :default => false
  end

  create_table "entities2details", :force => true do |t|
    t.integer "entity_id"
    t.integer "detail_id"
    t.integer "status_id"
    t.boolean "displayed_in_list_view",   :default => true
    t.integer "maximum_number_of_values"
    t.integer "display_order",            :default => 100
  end

  add_index "entities2details", ["detail_id"], :name => "entities2details__detail_id"
  add_index "entities2details", ["detail_id"], :name => "i_entities2details__detail_id"
  add_index "entities2details", ["entity_id"], :name => "entities2details__entity_id"
  add_index "entities2details", ["entity_id"], :name => "i_entities2details__entity_id"

  create_table "instances", :force => true do |t|
    t.integer  "entity_id"
    t.datetime "created_at"
    t.integer  "lock_version", :default => 0
    t.datetime "updated_at"
  end

  add_index "instances", ["entity_id"], :name => "i_instances__entity_id"

  create_table "integer_detail_values", :force => true do |t|
    t.integer  "detail_id"
    t.integer  "instance_id"
    t.integer  "value",        :limit => 8
    t.integer  "lock_version",              :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "invoices", :force => true do |t|
    t.integer  "invoice_number"
    t.datetime "invoice_date"
    t.integer  "account_id"
    t.float    "gross_amount"
    t.float    "amount"
    t.float    "vat_applied"
    t.text     "company"
    t.text     "address"
    t.text     "city"
    t.text     "country"
    t.text     "item"
  end

  create_table "links", :force => true do |t|
    t.integer "parent_id"
    t.integer "child_id"
    t.integer "relation_id"
  end

  add_index "links", ["child_id", "parent_id", "relation_id"], :name => "u_parent_child_relation", :unique => true
  add_index "links", ["child_id"], :name => "i_links__child_id"
  add_index "links", ["parent_id"], :name => "i_links__parent_id"

  create_table "paypal_communications", :force => true do |t|
    t.datetime "t"
    t.integer  "account_id"
    t.text     "txn_type"
    t.text     "communication_type"
    t.text     "direction"
    t.text     "content"
  end

  create_table "plugin_schema_info", :id => false, :force => true do |t|
    t.string  "plugin_name"
    t.integer "version"
  end

  create_table "preferences", :force => true do |t|
    t.integer "user_id"
    t.boolean "display_help"
  end

  create_table "relation_side_types", :force => true do |t|
    t.text "name"
  end

  create_table "relations", :force => true do |t|
    t.integer "parent_id",                                :null => false
    t.integer "child_id",                                 :null => false
    t.integer "parent_side_type_id",                      :null => false
    t.integer "child_side_type_id",                       :null => false
    t.text    "from_parent_to_child_name",                :null => false
    t.text    "from_child_to_parent_name"
    t.integer "lock_version",              :default => 0
  end

  add_index "relations", ["child_id"], :name => "i_relations__child_id"
  add_index "relations", ["parent_id"], :name => "i_relations__parent_id"

  create_table "schema_info", :id => false, :force => true do |t|
    t.integer "version"
  end

  create_table "transfers", :force => true do |t|
    t.datetime "created_at"
    t.integer  "account_id"
    t.integer  "user_id"
    t.integer  "detail_value_id"
    t.integer  "instance_id"
    t.integer  "entity_id"
    t.integer  "size",            :null => false
    t.text     "file"
    t.text     "direction"
  end

  create_table "user_types", :force => true do |t|
    t.text "name", :null => false
  end

  create_table "users", :force => true do |t|
    t.integer  "account_id",                                 :null => false
    t.integer  "user_type_id",                :default => 2
    t.string   "login",        :limit => 80
    t.string   "password",     :limit => nil
    t.string   "email",        :limit => 40
    t.string   "firstname",    :limit => 80
    t.string   "lastname",     :limit => 80
    t.string   "uuid",         :limit => 32
    t.string   "salt",         :limit => 32
    t.integer  "verified",                    :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "logged_in_at"
    t.text     "api_key"
  end

end
