require 'google/apis/gmail_v1'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'
require 'mail'
require_relative "../configuration.rb"

# GoogleTransport
# This class gets gmail.com emails using the google api. 
# You give this class a query, and it will download all the messages that
# match that query inside a folder with a prefix of @savedir.

class GmailTransport

  def initialize()
    @service = Google::Apis::GmailV1::GmailService.new
    @service.client_options.application_name = APPLICATION_NAME
    @service.authorization = authorize()
    @savedir=WORKDIR_PREFIX
  end

  ##
  # Ensure valid credentials, either by restoring from the saved credentials
  # files or intitiating an OAuth2 authorization. If authorization is required,
  # the user's default browser will be launched to approve the request.
  #
  # @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
  def authorize()
    client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts 'Open the following URL in the browser and enter the ' \
           "resulting code after authorization:\n" + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI
      )
    end
    credentials
  end
  
  def download_msgs_by_query(query, max_results=10, delete_msg=true)
  
    collection_of_matching_messages = @service.list_user_messages(
      'me',
      max_results: max_results,
      q: query
    )
    
    if collection_of_matching_messages.messages
    
      collection_of_matching_messages.messages.each do |message_meta_from_collection|
        savedir="#{@savedir}.#{SecureRandom.urlsafe_base64}"
    
        user_message = @service.get_user_message('me', message_meta_from_collection.id)  
    
        user_message.payload.headers.each do |some_header|
          #puts "From: #{some_header.value}" if some_header.name == "From"
          #puts "Subject: #{some_header.value}" if some_header.name == "Subject"

          # The subject of the email has a lot of information in it and will get processed later into a special yaml of specific work to do.
          if some_header.name == "Subject"
            Dir.mkdir(savedir) unless File.exists?(savedir)
            File.open("#{savedir}/subject.txt", 'w') {|f| f.write(some_header.value) }
          end
        end
   
        user_message.payload.parts.each do |user_message_part|

          # Case: Is an attachment
          if user_message_part.body.attachment_id
            @service.get_user_message_attachment('me', message_meta_from_collection.id, user_message_part.body.attachment_id) do | result, error|
              raise error if error
              message_data = result.data
              Dir.mkdir(savedir) unless File.exists?(savedir)
              File.open("#{savedir}/#{user_message_part.filename}", 'w') {|f| f.write(message_data) }
            end
 
          # Case: Has a body
          elsif user_message_part.body.data
            fn="unknown"
            if user_message_part.mime_type=="text/plain"
              fn="index.txt"
            elsif user_message_part.mime_type=="text/html"
              fn="index.html"
            end
            Dir.mkdir(savedir) unless File.exists?(savedir)
            File.open("#{savedir}/#{fn}", 'w') {|f| f.write(user_message_part.body.data.force_encoding("UTF-8")) }
           
          # Case: Has message parts
          elsif user_message_part.parts
            user_message_part.parts.each do |more_parts|

              if more_parts.mime_type=="text/plain"
                Dir.mkdir(savedir) unless File.exists?(savedir)
                File.open("#{savedir}/index.txt", 'w') {|f| f.write(more_parts.body.data) }
                next
              end

              if more_parts.mime_type=="text/html"
                Dir.mkdir(savedir) unless File.exists?(savedir)
                File.open("#{savedir}/index.html", 'w') {|f| f.write(more_parts.body.data) }
                next
              end

              if more_parts.filename && more_parts.filename!=""
                @service.get_user_message_attachment('me', message_meta_from_collection.id, more_parts.body.attachment_id) do | result, error|
                  raise error if error
                  message_data = result.data
                  Dir.mkdir(savedir) unless File.exists?(savedir)
                  File.open("#{savedir}/#{more_parts.filename}", 'w') {|f| f.write(message_data) }
                end
              end

              if more_parts.mime_type=="multipart/alternative"
                more_parts.parts.each do |part|

                  if part.headers.any? { |v| v.value.include? "text/html" }
                    Dir.mkdir(savedir) unless File.exists?(savedir)
                    File.open("#{savedir}/index.html", 'w') {|f| f.write(part.body.data) }
                  end

                end
              end
 
            end
          end
  
        end
    
        # Uncomment this if you want to delete the message after you process it.
        #@service.delete_user_message 'me', message_meta_from_collection.id if DESTROY_EMAIL_AFTER_PROCESSING
    
      end
    end
    return "finished"
  end

  def send_email_demo1()
    m = Mail.new(
      to: EMAIL_ADDRESS, 
      from: EMAIL_ADDRESS, 
      subject: "Test Subject",
      body:"Test Body"
    )
    message_object = Google::Apis::GmailV1::Message.new(raw: m.encoded)
    @service.send_user_message('me', message_object)
  end
  
  #find_some_stuff()
  #send_email_demo1()

end
