# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20131201184105) do

  create_table "trust_net_members", :force => true do |t|
    t.string   "idhash",     :limit => 64,  :null => false
    t.string   "doc_key",    :limit => 64,  :null => false
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
    t.string   "nick",       :limit => 128
  end

  add_index "trust_net_members", ["idhash", "doc_key"], :name => "index_trust_net_members_on_idhash_and_doc_key", :unique => true

  create_table "trust_net_result_histories", :force => true do |t|
    t.datetime "result_time", :null => false
  end

  add_index "trust_net_result_histories", ["result_time"], :name => "index_trust_net_result_histories_on_result_time"

  create_table "trust_net_results", :force => true do |t|
    t.string   "idhash",       :limit => 64, :null => false
    t.string   "doc_key",      :limit => 64, :null => false
    t.float    "verify_level",               :null => false
    t.float    "trust_level",                :null => false
    t.integer  "votes_count",                :null => false
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.datetime "result_time",                :null => false
  end

  add_index "trust_net_results", ["idhash", "doc_key"], :name => "index_trust_net_results_on_idhash_and_doc_key"
  add_index "trust_net_results", ["result_time", "idhash", "doc_key"], :name => "index_trust_net_results_on_result_time_and_idhash_and_doc_key"
  add_index "trust_net_results", ["result_time", "verify_level"], :name => "index_trust_net_results_on_result_time_and_verify_level"
  add_index "trust_net_results", ["verify_level", "votes_count"], :name => "index_trust_net_results_on_verify_level_and_votes_count"

  create_table "user_options", :force => true do |t|
    t.string   "idhash",        :limit => 64, :null => false
    t.string   "emails"
    t.string   "skype"
    t.string   "icq"
    t.string   "jabber"
    t.string   "phones"
    t.string   "facebook"
    t.string   "vk"
    t.string   "odnoklassniki"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.string   "doc_key",       :limit => 64, :null => false
  end

  add_index "user_options", ["idhash"], :name => "index_user_options_on_idhash", :unique => true

  create_table "user_trust_net_votes", :force => true do |t|
    t.string   "idhash",            :limit => 64, :null => false
    t.string   "vote_idhash",       :limit => 64, :null => false
    t.string   "vote_doc_key",      :limit => 64, :null => false
    t.integer  "vote_verify_level",               :null => false
    t.integer  "vote_trust_level",                :null => false
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.string   "doc_key",           :limit => 64, :null => false
  end

  add_index "user_trust_net_votes", ["idhash", "vote_idhash", "vote_doc_key"], :name => "index_utnv_id_vid_vdoc_key", :unique => true
  add_index "user_trust_net_votes", ["vote_idhash", "vote_doc_key"], :name => "index_user_trust_net_votes_on_vote_idhash_and_vote_doc_key"

end
