class AddExtraToPostHistory < ActiveRecord::Migration[7.0]
  def change
    # We need to pass collation nil to ensure that rails does not send one.
    # MySQL/MariaDB needs to pick one itself to ensure we get an appropriate binary collation.
    add_column :post_histories, :extra, :json, default: nil, collation: nil
  end
end
