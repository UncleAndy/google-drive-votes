class UserOption < ActiveRecord::Base
  attr_accessible :idhash, :doc_key, :emails, :skype, :icq, :jabber, :phones, :facebook, :vk, :odnoklassniki
end
