class EmailsOnPushWorker
  include Sidekiq::Worker

  def perform(project_id, recipients, push_data, send_from_committer_email = false, disable_diffs = false)
    project = Project.find(project_id)
    before_sha = push_data["before"]
    after_sha = push_data["after"]
    ref = push_data["ref"]
    author_id = push_data["user_id"]

    action = 
      if Gitlab::Git.blank_ref?(before_sha)
        :create 
      elsif Gitlab::Git.blank_ref?(after_sha)
        :delete
      else
        :push
      end

    compare = nil
    reverse_compare = false
    if action == :push
      compare = Gitlab::Git::Compare.new(project.repository.raw_repository, before_sha, after_sha)

      return false if compare.same

      if compare.commits.empty?
        compare = Gitlab::Git::Compare.new(project.repository.raw_repository, after_sha, before_sha)

        reverse_compare = true

        return false if compare.commits.empty?
      end
    end

    recipients.split(" ").each do |recipient|
      Notify.repository_push_email(
        project_id, 
        recipient, 
        author_id, 
        ref, 
        action,
        compare, 
        reverse_compare,
        send_from_committer_email,
        disable_diffs
      ).deliver
    end
  ensure
    compare = nil
    GC.start
  end
end
