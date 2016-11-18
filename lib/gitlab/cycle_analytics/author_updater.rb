module Gitlab
  module CycleAnalytics
    class AuthorUpdater < Updater
      def self.update!(event_result)
        new(event_result, User, :author).update!
      end
    end
  end
end
