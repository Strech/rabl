object @user => :person

attributes :username, :email, :location
node :registered_at do |user|
  user.created_at.to_s
end

node :role do |user|
  user.is_admin ? 'admin' : 'normal'
end

child :phone_numbers => :pnumbers do
  extends "users/phone_number"
end

node :node_numbers do |u|
  partial("users/phone_number", :object => u.phone_numbers, :locals => { :reversed => locals[:reversed].presence })
end
