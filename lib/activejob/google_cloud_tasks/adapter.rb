require 'activejob/google_cloud_tasks/config'
require 'google/cloud/tasks'
require 'google/cloud/tasks/v2/cloud_tasks_client'

module Activejob
  module GoogleCloudTasks
    class Adapter
      def initialize(project:, location:, cloud_tasks_client: Google::Cloud::Tasks.new(version: :v2))
        @project = project
        @location = location
        @cloud_tasks_client = cloud_tasks_client
      end

      def enqueue(job, attributes = {})
        formatted_parent = Google::Cloud::Tasks::V2::CloudTasksClient.queue_path(@project, @location, job.queue_name)
        relative_uri = "#{Activejob::GoogleCloudTasks::Config.path}/perform?job=#{job.class.to_s}&#{job.arguments.to_param}"

        task = {
          app_engine_http_request: {
            http_method: :GET,
            relative_uri: relative_uri
          }
        }
        task[:schedule_time] = Google::Protobuf::Timestamp.new(seconds: attributes[:scheduled_at].to_i) if attributes.has_key?(:scheduled_at)
        @cloud_tasks_client.create_task(formatted_parent, task)
      end

      def enqueue_at(job, scheduled_at)
        enqueue job, scheduled_at: scheduled_at
      end
    end
  end
end
