namespace :app do

  namespace :convert_attachments do

    desc "Converts attachment fu attachments to carrier wave attachments"
    task :attachment_fu_to_carrier_wave => :environment do
      puts "This will convert attachment fu images to carrierwave format. Proceed? [y/n]"
      response = $stdin.gets.chomp
      if response.upcase == 'Y'
        begin
          # check that the migration and the new classes exist
          correct_code_base = 'Upload'.constantize rescue false
          if correct_code_base
            total_count = Upload.count
            uploads = Upload.where('uploads.filename is not null AND uploads.attachment is null')
            converted_count = 0
            total_uploads_with_attachments = uploads.length
            uploads.each do |upload|
              original_file = File.join(store_dir(upload), upload.filename)
              if File.exists?(original_file)
                upload.attachment.store!(File.open(original_file))
                success = upload.save
                print success ? 'c ' : 'e '
                converted_count += 1 if success
              end
            end
          else
            puts "Upload class has not been defined. This rake task requires the Asset class 
                  \nto have been renamed Upload and the necessary database migrations. 
                  \nBRPM 2.6 is the first version with the required code. \n\nNo changes were made."
            exit
          end
        rescue => e
          puts "There was an error: " + e.message
        else
          puts "Conversion complete. Processed #{converted_count} of #{total_uploads_with_attachments} legacy assets out of #{total_count} total uploads."
        end
      else
        puts "You did not enter 'Y', so the table was left unchanged."
      end
    end
    
  end

  def partition_dir(model)
    ("%08d" % model.id).scan(/\d{4}/).join("/")
  end

  # store dir is composed of root_dir, model_dir, partition_dir
  # override/change any of those to fit your needs
  def store_dir(model)
    File.join Rails.root, "public", "assets", partition_dir(model)
  end

end