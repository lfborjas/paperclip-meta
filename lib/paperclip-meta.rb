module Paperclip
  class Attachment
    alias :original_post_process_styles :post_process_styles
    alias :original_save :save

    # If attachment deleted - destroy meta data
    def save
      unless @queued_for_delete.empty?
        instance_write(:meta, ActiveSupport::Base64.encode64(Marshal.dump({}))) if instance.respond_to?(:"#{name}_meta=")
      end
      original_save
    end
      
    # If model has #{name}_meta column we getting sizes of processed
    # thumbnails and saving it to #{name}_meta column.
    def post_process_styles
      original_post_process_styles

      if instance.respond_to?(:"#{name}_meta=")
        meta = {}

        @queued_for_write.each do |style, file|
          begin
              data = EXIFR::JPEG.new file
              date_taken = if data.exif?
                               data.date_time || data.date_time_original || data.date_time_digitized
                           else
                               nil
                           end
              if data.exif?
                  unless data.gps.nil?
                      latitude = data.gps.latitude
                      longitude = data.gps.longitude
                  end
              end
          rescue Exception => e
              date_taken = nil
              latitude = nil
              longitude = nil
          end

          begin
            geo = Geometry.from_file file
            meta[style] = {:width => geo.width.to_i, :height => geo.height.to_i,
                           :size => File.size(file), :date_taken => date_taken,
                           :latitude => latitude, :longitude => longitude
                          }
          rescue NotIdentifiedByImageMagickError => e
            meta[style] = {}
          end
        end

        instance_write(:meta, ActiveSupport::Base64.encode64(Marshal.dump(meta)))
      end
    end

    # Meta access methods
    [:width, :height, :size, :date_taken, :latitude, :longitude].each do |meth|
      define_method(meth) do |*args|
        style = args.first || default_style
        meta_read(style, meth)
      end
    end

    def image_size(style = default_style)
      "#{width(style)}x#{height(style)}"
    end

    private
    def meta_read(style, item)
      if instance.respond_to?(:"#{name}_meta") && instance_read(:meta)
        if meta = Marshal.load(ActiveSupport::Base64.decode64(instance_read(:meta)))
          meta.key?(style) ? meta[style][item] : nil
        end
      end
    end    

  end
end
