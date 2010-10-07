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

ActiveRecord::Schema.define(:version => 20101007013004) do

  create_table "activations", :force => true do |t|
    t.integer  "user_id"
    t.string   "state"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "albums", :force => true do |t|
    t.string   "name"
    t.string   "slug"
    t.string   "cover_url"
    t.integer  "artist_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "albums", ["slug"], :name => "index_albums_on_slug"

  create_table "artists", :force => true do |t|
    t.string   "name"
    t.string   "slug"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "artists", ["slug"], :name => "index_artists_on_slug"

  create_table "comments", :force => true do |t|
    t.text     "text"
    t.integer  "user_id"
    t.integer  "song_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "memberships", :force => true do |t|
    t.integer  "user_id"
    t.integer  "playlist_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "playlists", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "slug"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.boolean  "private",     :default => false
  end

  create_table "playlists_users", :id => false, :force => true do |t|
    t.integer "playlist_id"
    t.integer "user_id"
  end

  create_table "pools", :force => true do |t|
    t.integer  "playlist_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pools_songs", :id => false, :force => true do |t|
    t.integer "pool_id"
    t.integer "song_id"
  end

  create_table "queue_items", :force => true do |t|
    t.integer  "song_id"
    t.integer  "playlist_id"
    t.integer  "user_id"
    t.float    "priority"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "song_ratings", :force => true do |t|
    t.integer  "user_id"
    t.integer  "score"
    t.integer  "song_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "songs", :force => true do |t|
    t.string   "title"
    t.integer  "play_count",         :default => 0
    t.string   "audio_file_name"
    t.string   "audio_content_type"
    t.integer  "audio_file_size"
    t.datetime "audio_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "custom_set"
    t.integer  "artist_id"
    t.integer  "album_id"
    t.float    "rating",             :default => 0.0
  end

  create_table "users", :force => true do |t|
    t.string   "name",                                                :null => false
    t.boolean  "admin",                            :default => false, :null => false
    t.string   "email",                                               :null => false
    t.string   "crypted_password"
    t.string   "password_salt"
    t.string   "persistence_token",                                   :null => false
    t.string   "single_access_token",                                 :null => false
    t.string   "perishable_token",                                    :null => false
    t.integer  "login_count",                      :default => 0,     :null => false
    t.integer  "failed_login_count",               :default => 0,     :null => false
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string   "current_login_ip"
    t.string   "last_login_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "facebook_uid",        :limit => 8
  end

  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["perishable_token"], :name => "index_users_on_perishable_token"

end
