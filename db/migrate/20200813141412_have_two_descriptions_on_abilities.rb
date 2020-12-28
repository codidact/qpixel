class HaveTwoDescriptionsOnAbilities < ActiveRecord::Migration[5.2]
  def change
    add_column :abilities, :summary, :text

    Ability.unscoped.all.each do |a|
      a.update summary: a.description
    end
  end
end
