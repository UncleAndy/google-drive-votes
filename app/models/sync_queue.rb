class SyncQueue < ActiveRecord::Base
  attr_accessible :query_id, :status, :cmd, :data

  default_scope order('created_at')
  scope :for_input, ->{ where(:status => 'new') }
  scope :for_output, ->{ where(:status => 'out') }

  # Статусы:
  # 'out' - для передачи наружу
  # 'new' - для локальной обработки, а затем для передачи наружу
  # 'done' - обработанные записи
  
  before_save do
    self.query_id ||= Guid.new.hexdigest
  end
end
