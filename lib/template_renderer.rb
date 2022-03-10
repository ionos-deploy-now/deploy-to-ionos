# frozen_string_literal: true

class TemplateRenderer
  def initialize(options)
    @files = options[:files].split(',')
  end

  def render(app_url, database)
    @files.each do |file|
      content = File.read(file).gsub('@APP_URL@', app_url)
      unless database.empty?
        content = content.gsub('@DB_USERNAME@', database[:username])
                         .gsub('@DB_PASSWORD@', database[:password])
                         .gsub('@DB_HOST@', database[:host])
                         .gsub('@DB_NAME@', database[:name])
      end
      File.write(file, content)
    end
  end
end
