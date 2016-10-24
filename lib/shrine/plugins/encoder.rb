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
          uploader.plugin opts[:encoder] if opts.key? :encoder
          uploader.opts[:encoder_store] = opts.fetch :store, uploader.opts.fetch(:store, false)
        end
      end

      module InstanceMethods
        def process io, context
          case context[:action]
          when :store
            { original: io }.merge versions(context[:payload])
          end
        end

        def versions _data
          {}
        end
      end

      module AttacherMethods
        def start_encoding
        end

        def webhook_callback request
        end

        def encodings
          []
        end

        private

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
