require 'csv'

class RolesMapCsv
  def initialize(teams, groups, users)
    @teams = teams
    @groups = groups
    @users = users
  end

  def generate
    CSV.generate do |csv|
      csv << header
      [@teams, @groups, @users].each do |objects|
        append_rows(objects, csv)
      end
    end
  end

  def header
    ['Type', 'Name', 'Role name', 'Role description']
  end

  def append_rows(objects, csv)
    objects.each do |object|
      object.roles.each do |role|
        csv << row(object, role)
      end
    end
  end

  def row(object, role)
    [object.class.to_s, object.name, role.name, role.description]
  end
end