class SyncHost < ActiveRecord::Base
  attr_accessible :url, :secret, :host_id, :active

  scope :for_output, ->{ where(:active => true) }

  def active?
    active
  end
end
