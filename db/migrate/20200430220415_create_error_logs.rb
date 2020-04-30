class CreateErrorLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :error_logs do |t|
      t.references :community, foreign_key: true
      t.references :user, foreign_key: true
      t.string :klass
      t.text :message
      t.text :backtrace
      t.text :request_uri, null: false
      t.string :host, null: false

      t.timestamps
    end
  end
end
