module PostCreationValidations
  extend ActiveSupport::Concern

  included do
    validate :no_mathjax_in_title, on: :create
    validate :post_type_requires_parent, on: :create
    validate :post_type_has_category, on: :create
    validate :can_post_in_category, on: :create

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
      if category.present? && !current_user.can_post_in?(category)
        errors.add(:base, helpers.i18ns('posts.category_low_trust_level', name: category.name))
      end
    end
  end
end
