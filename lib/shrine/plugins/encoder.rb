require 'shrine'
require "down"

class Shrine
  module Plugins
    module Encoder
      def self.load_dependencies uploader, *_opt
        uploader.plugin :backgrounding
        uploader.plugin :webhook
      end

      def self.configure uploader, opts = {}
        uploader::Attacher.promote { |data| start_encoding data }
      end

      module InstanceMethods
        def process io, context
          case context[:phase]
          when :store
            { original: io }.merge _versions(context[:payload])
          end
        end

        private

        def _versions payload
          Hash[*_outputs(payload).flatten].symbolize_keys
        end

        # TODO: This is Zencoder Specific
        def _outputs payload
          [].tap do |out|
            payload['outputs'].each do |output|
              label, url = [output['label'], output['url']]

              out << [label, get_file(url)]

              output.fetch('thumbnails', []).each do |thumbnail|
                thumbnail.fetch('images', []).each_with_index do |image, index|
                  thumb_label, thumb_url = [thumbnail['label'], image['url']]

                  out << ["#{thumb_label}_#{index}", get_file(thumb_url)]
                end
              end
            end
          end
        end

        private

        def get_file url
          Down.download url
        rescue Down::NotFound => error
          puts error.cause
          raise
        end
      end

      module AttacherMethods

        # TODO: This is Zencoder Specific
        def start_encoding data
          return if encodings.blank?

          Zencoder::Job.create input: url,
                               outputs: encodings,
                               notifications: [{ url: callback_url }]
        end

        def encodings
        end

        private

        def _encodings
          encodings || []
        end

        def callback_url
          File.join endpoint_url,
                    CGI::escape(record.class.name.underscore),
                    record.id.to_s,
                    name.to_s,
                    'callback'
        end
      end
    end

    register_plugin :encoder, Encoder
  end
end
