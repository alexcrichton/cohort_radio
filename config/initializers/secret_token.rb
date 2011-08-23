# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
CohortRadio::Application.config.secret_token = ENV['SECRET_TOKEN'] || '7c4766d5659d762c2da507651e7a67baa018762e721012b68f27c2f420650d70bd1e8c575144861c1321c224747a2d7bee6d1d74c47f0d3a2fc4f69e8e99a1aa'
