require 'json'
require 'yaml'
require 'nokogiri'

PASSWORD="doit" # Or you can pick a better password, I'm not your mother
require_relative "../configuration.rb"

# This class expects 
class JobScanner

  def initialize()
  end

  def process
    all_workdir_items = []
    authentic_workdir_items = []

    Dir.glob("#{WORKDIR_PREFIX}.*").each do |f|
      all_workdir_items << f
    end

    all_workdir_items.each do |job_dir|
      Dir.entries(job_dir).each do |file|

        # process the original subject line, which was stored as its own file.
        # this is where we can evict non-authentic requests.
        if file.include? "subject.txt"
          decisions=process_subject_semantics("#{job_dir}/#{file}") 
          if decisions[:password]==PASSWORD
            File.open("#{job_dir}/configuration.yml", "w") { |file| file.write(decisions.to_yaml) }
          end
        end

        # email bodies treat images very differently and we need to postprocess them
        # to make them render correctly in a web browser.
        translate_cid_to_original_src("#{job_dir}/#{file}") if file.include? "index.html"

      end
    end

    # Halfhearted design decision: Instead of storing the configuration in memory, we're storing it on disk
    # so that other glue-processes can easily access it much later in time, such as after a reboot, or from
    # an unrelated language.
    all_workdir_items.each do | workdir_item |
       Dir.entries(workdir_item).each do |file|
         if file.include? 'configuration.yml'
           config=YAML.load(File.read("#{workdir_item}/#{file}")) rescue {:password=>false}
           authentic_workdir_items << workdir_item if config[:password]==PASSWORD
         end
       end
    end

    authentic_workdir_items.to_json

  end

  # We can perform additional processing on the cmd= token.
  def process_subject_cmd_request(token, decisions)
    decisions[:cmd]=token

    if decisions[:cmd].start_with? "get"
      decisions[:cmd].slice!(/get\s*/)
      decisions[:download_url] = decisions[:cmd]
      decisions[:cmd]="download_url"
    end

  end

  # By the time this method runs, our unique subject query has long since finished downloading onto disk.
  # We can evict messages that don't pass our very weak requirements for authenticity at this phase.
  def process_subject_semantics(subject_file)
    data=File.read(subject_file)
  
    # supbuddy=<pw> tags=csv category=category (title|cmd)=these are the final part of the subject and passed into these directives without formatting
    # intended examples.
    # supbuddy=doit tags=dovetails category=woodworking title=I am terrible at cutting dovetails
    # supbuddy=doit cmd=get https://something/someresource
    
    decisions={}
    request_tokens=[]
    data.each_line do |line|
    
      line.split do |token|
    
        # These special tokens indicate that we're going to just record the rest of the subject line as freeform text.
        if token.match?('cmd=')
          token=line.split('cmd=').last.strip
          process_subject_cmd_request(token, decisions)
          break
        end
    
        if token.match?('title=')
          decisions[:title]=line.split('title=').last.strip
          decisions[:cmd]="publish_email_as_webpage"
          break
        end
    
        # Otherwise, toss the token into a queue for more processing as specific meanings.
        d=token.split '='
        request_tokens << {:action=>d.first, :value=>d.last}
      end
    end
    
    request_tokens.each do |thing|
      case thing[:action]
      when 'supbuddy'
        decisions[:password]=thing[:value]
      when 'tags'
        decisions[:tags]=[]
        thing[:value].split(',').each do |c|
          decisions[:tags] << c
        end
      when 'category'
        decisions[:category] = thing[:value]
      when 'title'
        decisions[:title] = thing[:value]
      end
    end
    
    decisions
   
  end

  # Emails use a content-id reference for img src values, which somehow must map to an attachment.
  # Fortunately these clients seem to all provide a hint of the original file name, which we have
  # downloaded the attachments from the email as originally named. Each client saves this original
  # filename in a different place, so we have to go on a bit of a treasure hunt to collect them.
  def translate_cid_to_original_src(html_file)
 
    doc = File.open(html_file) { |f| Nokogiri::HTML(f) }
    doc.xpath("//img").each do |img|
      found=nil
    
      # Pass One, find hints to restore img src.
      img.each do |n,v|

        found=v if n=='title' # Outlook OWA web client.
        found=v if n=='alt'   # gmail.
    
        if n=='src'
          if v.match?(/cid:.*?@/)
            found=v.sub(/@.*/,'').sub('cid:','') # Outlook 2016 Mac thick client.
          end
        end
    
        break if found
      end

      # Pass Two, restore the img src.
      break unless found
      img.each do |n,v|
        if n=="src"
          img.attributes["src"].value=found
        end
      end

      # Save the updated file
      File.write(html_file, doc)
    end

  end
  
end
