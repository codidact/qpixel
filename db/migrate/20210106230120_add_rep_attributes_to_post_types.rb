class AddRepAttributesToPostTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :post_types, :upvote_rep, :integer
    add_column :post_types, :downvote_rep, :integer

    rep_settings = ['Question', 'Answer', 'Article'].map { |pt| ["#{pt}UpVoteRep", "#{pt}DownVoteRep"] }.flatten
    SiteSetting.unscoped.where(name: rep_settings).delete_all

    rep_changes = {
      'Question' => { upvote_rep: 5, downvote_rep: -2 },
      'Answer' => { upvote_rep: 10, downvote_rep: -2 },
      'Article' => { upvote_rep: 10, downvote_rep: -2 },
      'HelpDoc' => { upvote_rep: 0, downvote_rep: 0 },
      'PolicyDoc' => { upvote_rep: 0, downvote_rep: 0 },
      'Wiki' => { upvote_rep: 0, downvote_rep: 0 }
    }
    rep_changes.each do |pt, update|
      PostType[pt]&.update(update)
    end
  end
end
