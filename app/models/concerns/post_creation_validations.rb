module PostCreationValidations
  extend ActiveSupport::Concern

  # rubocop:disable Metrics/BlockLength
  included do
    validate :no_mathjax_in_title, on: :create
    validate :post_type_requires_parent, on: :create
    validate :post_type_has_category, on: :create
    validate :can_post_in_category, on: :create
    validate :identical_post_spam, on: :create
    validate :no_active_spam_flags, on: :create

    after_create :escalate_suspicious_cidr

    private

    def no_mathjax_in_title
      if title? && title.include?('$$')
        errors.add(:base, I18n.t('posts.no_block_mathjax_title'))
      end
    end

    def post_type_requires_parent
      if post_type.has_parent? && parent.nil?
        errors.add(:base, helpers.i18ns('posts.type_requires_parent', type: post_type.name))
      end
    end

    def post_type_has_category
      if post_type.has_category? && category.nil? && parent.nil?
        errors.add(:base, helpers.i18ns('posts.type_requires_category', type: post_type.name))
      end
    end

    def can_post_in_category
      if category.present? && !user.can_post_in?(category)
        errors.add(:base, helpers.i18ns('posts.category_low_trust_level', name: category.name))
      end
    end

    def identical_post_spam
      threshold = AppConfig.spam_protection['identical_post_spam_threshold']
      prev_non_deleted_count = Post.unscoped.where(user: user, deleted: false).count
      unless prev_non_deleted_count >= threshold
        identical_posts = Post.unscoped.where(user: user, body_markdown: body_markdown).where.not(id: id)
        if identical_posts.any?
          errors.add(:base, ApplicationRecord.useful_err_msg.sample)
        end
      end
    end

    def no_active_spam_flags
      posts_threshold = AppConfig.spam_protection['spam_flag_posts_threshold']
      time_threshold = AppConfig.spam_protection['spam_flag_time_threshold']
      prev_non_deleted_count = Post.unscoped.where(user: user, deleted: false).count
      unless prev_non_deleted_count >= posts_threshold
        active = Post.unscoped
                     .joins(Arel.sql("INNER JOIN flags ON flags.post_type = 'Post' AND flags.post_id = posts.id"))
                     .joins(Arel.sql('INNER JOIN post_flag_types ON flags.post_flag_type_id = post_flag_types.id'))
                     .where(flags: { status: nil },
                            post_flag_types: { name: "it's spam" },
                            posts: { user_id: user.id })
        helpful = Post.unscoped
                      .joins(Arel.sql("INNER JOIN flags ON flags.post_type = 'Post' AND flags.post_id = posts.id"))
                      .joins(Arel.sql('INNER JOIN post_flag_types ON flags.post_flag_type_id = post_flag_types.id'))
                      .where(flags: { status: 'helpful' },
                             post_flag_types: { name: "it's spam" },
                             posts: { user_id: user.id })
                      .where('flags.created_at <= ?', time_threshold.days.ago)
        if active.any? || helpful.any?
          errors.add(:base, ApplicationRecord.useful_err_msg.sample)
        end
      end
    end

    def escalate_suspicious_cidr
      CheckCIDRJob.perform_later(self)
    end
  end
  # rubocop:enable Metrics/BlockLength
end
