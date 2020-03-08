# Specify a directory prefix you want. Each email will create a directory
# that starts with this pattern and a random suffix. 
WORKDIR_PREFIX="/tmp/mailthing"

DESTROY_EMAIL_AFTER_PROCESSING=false

EMAIL_ADDRESS=`cat ~/.my_email`.chop
raise "save your email in a line by itself as ~/.my_email" unless EMAIL_ADDRESS != ""

# You need to get this working by following the ruby quickstart guide on the gmail website1
# https://developers.google.com/gmail/api/quickstart/ruby
# Change your configuration to refer to wherever you are hiding both of these credentials.
# You can pick a permission you want from https://www.rubydoc.info/github/google/google-api-ruby-client/Google/Apis/GmailV1
CREDENTIALS_PATH="#{ENV['HOME']}/.mike_env/credentials/gmail.api".freeze
TOKEN_PATH =  "#{ENV['HOME']}/.mike_env/credentials/token.all_perms.yaml".freeze

# Please refer to the configuration.rb file for where the authentication tokens are being saved.
# They are not configured in here.
OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
APPLICATION_NAME = 'Sinatra Blogomatic'.freeze
# The file token.yaml stores the user's access and refresh tokens, and is
# created automatically when the authorization flow completes for the first
# time.

# This one allows total destruction of your emails, maybe even account:
TOKEN_PATH =  "#{ENV['HOME']}/.mike_env/credentials/token.all_perms.yaml".freeze
SCOPE = Google::Apis::GmailV1::AUTH_SCOPE

# This access is very safe because it is read-only:
#TOKEN_PATH =  "#{ENV['HOME']}/credentials/token.readonly.yaml".freeze
#SCOPE = Google::Apis::GmailV1::AUTH_GMAIL_READONLY

# This will debug the universe, leave it off.
#Google::Apis.logger.level = Logger::DEBUG
