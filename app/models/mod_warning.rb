class ModWarning < ApplicationRecord
    self.table_name = 'warning' # Warning class name not accepted by Rails, hence this needed
end
