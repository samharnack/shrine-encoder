require 'zencoder'

class Shrine
  module Plugins
    module Zencoder
      class Importer < ActiveJob::Base
        queue_as :urgent

        def perform data, payload
          type, id = data['record']
          name = data['name']
          record = type.classify.constantize.find id
          attacher = record.send "#{name}_attacher"
          attacher.promote attacher.get, action: :store, payload: payload
        end
      end

      module AttacherMethods
        def start_encoding data
          ::Zencoder::Job.create input: url,
                                 test: !Rails.env.production?,
                                 outputs: encodings,
                                 notifications: [{ url: callback_url }]
        end

        def webhook_callback request
          Importer.perform_later dump, JSON.parse(request.body.read)
        end
      end

      module InstanceMethods
        def versions payload
          Hash[*outputs(payload).flatten].symbolize_keys
        end

        private

        def outputs payload
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

        def get_file url
          Down.download url
        rescue Down::NotFound => error
          puts error.cause
          raise
        end
      end
    end

    register_plugin :zencoder, Zencoder
  end
end
