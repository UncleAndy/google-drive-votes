class UserOption < ActiveRecord::Base
  attr_accessible :idhash, :emails, :skype, :icq, :jabber, :phones, :facebook, :vk, :odnoklassniki
end
