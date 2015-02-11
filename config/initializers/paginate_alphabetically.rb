require File.expand_path(File.join(Rails.root, 'lib/paginate_alphabetically/paginate_alphabetically'))
require File.expand_path(File.join(Rails.root, 'lib/paginate_alphabetically/view_helpers'))

ActiveRecord::Base.extend(PaginateAlphabetically)
ActionView::Base.class_eval { include PaginateAlphabetically::ViewHelpers }
