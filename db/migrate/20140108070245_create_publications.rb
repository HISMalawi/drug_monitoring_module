class CreatePublications < ActiveRecord::Migration
  def change
    create_table :publications, :primary_key => :publication_id do |t|
      t.string :author
      t.string :title
      t.date :publish_year
      t.has_attached_file :avatar
      t.timestamps
    end
  end
end

