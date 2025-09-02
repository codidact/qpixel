require 'test_helper'

class CategoriesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get index' do
    get :index
    assert_response(:success)
    assert_not_nil assigns(:categories)
  end

  test 'homepage should show categories in the correct order' do
    get :homepage
    assert_not_nil assigns(:header_categories)
    seq = 0
    id = 0
    assigns(:header_categories).each do |category|
      if category.sequence.nil?
        assert category.id > id, "Category #{category.id} not after #{id}"
      else
        assert category.sequence >= seq, "Category #{category.id} sequence #{category.sequence} not greater than #{seq}"
      end
      seq = category.sequence || seq
      id = category.id
    end
  end

  test ':homepage should correctly show the homepage category' do
    get :homepage
    assert_response(:success)
    @category = assigns(:category)
    assert_not_nil @category
    assert @category.homepage?
  end

  test ':homepage should redirect to the categories list if there is no default category' do
    Category.where(is_homepage: true).destroy_all

    get :homepage
    assert_response(:found)
    assert_redirected_to(categories_path)
  end

  test 'should correctly show public categories' do
    public_categories = categories.select(&:public?)

    assert_not public_categories.empty?

    public_categories.each do |category|
      try_show_category(category)

      assert_response(:success)
      assert_not_nil assigns(:category)
      assert_not_nil assigns(:posts)
    end
  end

  test 'fake community should never be shown' do
    RequestContext.community = communities(:fake)
    request.env['HTTP_HOST'] = 'fake.qpixel.com'

    try_show_category(categories(:main))

    assert_response(:not_found)
  end

  test 'categories should only be shown to those who can see them' do
    users.each do |user|
      sign_in user

      categories.each do |category|
        try_show_category(category)

        if category.public? || user.can_see_category?(category)
          assert_response(:success)
        else
          assert_response(:not_found)
        end

        assert_not_nil assigns(:category)
      end
    end
  end

  test ':new should require the user to be an admin' do
    users.each do |user|
      sign_in user

      get :new

      if user.admin?
        assert_response(:success)
        assert_not_nil assigns(:category)
      elsif @controller.helpers.user_signed_in?
        assert_response(:not_found)
      else
        assert_redirected_to_sign_in
      end
    end
  end

  test 'should require authentication to create category' do
    try_create_category
    assert_redirected_to_sign_in
  end

  test 'should require admin to create category' do
    sign_in users(:standard_user)
    try_create_category
    assert_response(:not_found)
  end

  test 'should allow admins to create category' do
    sign_in users(:admin)
    try_create_category

    assert_response(:found)
    assert_not_nil assigns(:category)
    assert_not_nil assigns(:category).id
    assert_equal false, assigns(:category).errors.any?
    assert_redirected_to category_path(assigns(:category))
  end

  private

  def try_create_category(**opts)
    name = opts[:name] || 'test'
    short_wiki = opts[:short_wiki] || 'test'
    license = opts[:license] || licenses(:cc_by_sa)
    color_code = opts[:color_code] || 'blue'
    display_post_types = opts[:display_post_types] || [Question.post_type_id]
    post_types = opts[:post_types] || [Question, Answer]
    tag_set = opts[:tag_set] || tag_sets(:main)

    post :create, params: { category: { name: name,
                                        short_wiki: short_wiki,
                                        display_post_types: display_post_types,
                                        post_type_ids: post_types.map(&:post_type_id),
                                        tag_set_id: tag_set.id,
                                        color_code: color_code,
                                        license_id: license.id } }
  end

  def try_show_category(category)
    get :show, params: { id: category.id }
  end
end
