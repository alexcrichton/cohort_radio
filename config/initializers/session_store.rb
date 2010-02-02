# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_cradio_session',
  :secret      => '279947006bb6e577873f2afb9339e3d325dc9e93062b645dc73d8879e119e6e31414420006f2ddded9e6c6378549a5756da3d46949bb644b19ca6594644a8854'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
