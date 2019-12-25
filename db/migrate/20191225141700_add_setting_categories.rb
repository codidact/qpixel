class AddSettingCategories < ActiveRecord::Migration[5.2]
  def change
    # This migration only needs to run if there are already existing settings without a category.
    # That's not the case in test, because they get seeded as necessary, so we don't need to run this.
    return if Rails.env.test?

    categories = {
      site_name: :site_details,
      site_logo_path: :site_details,
      question_up_vote_rep: :reputation_and_voting,
      question_down_vote_rep: :reputation_and_voting,
      answer_up_vote_rep: :reputation_and_voting,
      answer_down_vote_rep: :reputation_and_voting,
      allow_self_votes: :reputation_and_voting,
      asking_guidance: :help_and_guidance,
      answering_guidance: :help_and_guidance,
      administrator_contact_email: :site_details,
      hot_questions_count: :display,
      admin_badge_character: :display,
      mod_badge_character: :display,
      soft_delete_transfer_user: :advanced_settings,
      new_user_initial_rep: :reputation_and_voting,
      se_api_client_id: :integrations,
      se_api_client_secret: :integrations,
      se_api_key: :integrations,
      content_license_name: :site_details,
      content_license_link: :site_details,
      max_tag_length: :site_details,
      max_upload_size: :advanced_settings
    }

    categories.each do |name, category|
      puts "#{name.to_s.camelize}: #{category.to_s.camelize}"
      SiteSetting.find_by(name: name.to_s.camelize).update(category: category.to_s.camelize)
    end
  end
end