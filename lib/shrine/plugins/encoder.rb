require 'shrine'
require 'down'

class Shrine
  module Plugins
    module Encoder

      class << self
        def load_dependencies uploader, *_opt
          uploader.plugin :backgrounding
          uploader.plugin :webhook
        end

        def configure uploader, opts = {}
          uploader::Attacher.promote { |data| _start_encoding data }
          uploader.plugin opts[:encoder] if opts.key? :encoder
        end
      end

      module InstanceMethods
        def process io, context
          case context[:action]
          when :store
            { original: io }.merge _versions(context[:payload])
          end
        end

        def versions data
        end

        private

        def _versions data
          versions(data) || {}
        end
      end

      module AttacherMethods
        def start_encoding data
        end

        def webhook_callback request
        end

        def encodings
        end

        private

        def _start_encoding data
          start_encoding data unless _encodings.blank?
        end

        def _encodings
          encodings || []
        end

        def callback_url
          File.join endpoint_url,
                    CGI.escape(record.class.name.underscore),
                    record.id.to_s,
                    name.to_s,
                    'callback'
        end
      end
    end

    register_plugin :encoder, Encoder
  end
end
