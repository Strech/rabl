object @post
filters @filters

attributes :title, :body
allowed_attributes :user_id => :uid

allowed_child :user do
  attributes :email, :username
  allowed_attributes :is_admin

  allowed_child :phone_numbers => :phones do |phones|
    collection phones, object_root: false

    attributes :formatted, :is_primary
    allowed_attributes :name
  end
end
