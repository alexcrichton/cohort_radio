# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key    => '_cradio_session',
  :secret => 'ae9caf830d0e1347d8998581210bcbbd464ff65606ae8c5509c371342b58f984c09ec7d813760610cbae94a44b9994ead0b03394c2168d3e646b166fdefd774d'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
