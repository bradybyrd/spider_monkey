require 'activerecord-jdbc-adapter'

ActiveRecord::ConnectionAdapters::JdbcTypeConverter::AR_TO_JDBC_TYPES[:timestamp] = \

  [ lambda {|r| ActiveRecord::ConnectionAdapters::Jdbc::Types::TIMESTAMP == r['data_type'].to_i},
                          lambda {|r| r['type_name'] =~ /^timestamp$/i},
                          lambda {|r| r['type_name'] =~ /^datetime$/i},
                          lambda {|r| r['type_name'] =~ /^date/i},
                          lambda {|r| r['type_name'] =~ /^integer/i}]  #Num of milliseconds for SQLite3 JDBC Driver



Windows = (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)

# Note if changed - must also change in streamstep.py and script_helper.rb
PRIVATE_PREFIX = "__SS__" # to denote private data in scripts

#governs the interval that Request/Steps will poll the server 0=never
CHECK_INTERVAL = 0

DEFAULT_DATE_FORMATS_FOR_SELECT = [
  ['MM/DD/YYYY HH:MM', '%m/%d/%Y %I:%M %p' ],
  ['DD/MM/YYYY HH:MM', '%d/%m/%Y %I:%M %p' ],
  ['YYYY/MM/DD HH:MM', '%Y/%m/%d %I:%M %p' ],
  ['MON-DD-YYYY', '%b-%d-%Y']
]

DEFAULT_DATE_FORMATS_FOR_DATEPICKER = {
  '%m/%d/%Y %I:%M %p' => 'mm/dd/yy',
  '%d/%m/%Y %I:%M %p' => 'dd/mm/yy',
  '%Y/%m/%d %I:%M %p' => 'yy/mm/dd',
  '%b-%d-%Y' => 'M-dd-yy'
}


# Fixme: This was changed on 1/13/13 and caused os x machines (at least) not to start
# I do not have time to check why this is needed (it is not typically needed) but
# this revised code at least restores the old behavior if the environmental variable
# is not set, which for RVM users it is most often not set.  We should make sure our
# installer sets this or we will be in trouble on other installs too.
ruby_home = ENV["JRUBY_HOME"]
if Windows
  # manually assemble the path with Windows friendly delimiters
  # FIXME: not clear why File.join is
  # not working correctly here for Windows machines.
  RUBY_PATH = "#{ruby_home}\\bin\\jruby.bat"
else
  unless ruby_home.blank?
    # assemble the path from the env variable
    RUBY_PATH = File.join(ruby_home,"bin","jruby")
  else
    # ask the OS where to find jruby
    RUBY_PATH = `which jruby`.try(:chomp)
  end
end

# 2013-01-18, mbhandek, patch for avoiding catalina logger getting used in jruby automations
env_java_opts = ENV["JAVA_OPTS"]

begin
  if env_java_opts
    class_loader_property = "-Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager"
    ENV["JAVA_OPTS"].gsub!(class_loader_property,"") if env_java_opts.include?(class_loader_property)
    load File.join(Rails.root, 'config', 'initializers', 'string.rb')
    ENV["JAVA_OPTS"] = "#{ENV['JAVA_OPTS']}".merge_opts!($AUTOMATION_JAVA_OPTS) if $AUTOMATION_JAVA_OPTS && ENV["RAILS_ENV"] != 'test'
  end
rescue
  Rails.logger.warn("WARNING: Automation may not run properly because JAVA_OPTS couldn't be updated. (#{env_java_opts})")
end

Rails.logger.info("\n**** Automation Configuration ****")
Rails.logger.info("\nRUBY_PATH=#{RUBY_PATH}")
Rails.logger.info("\nJAVA_OPTS=#{ENV["JAVA_OPTS"]}")
Rails.logger.info("\nJAVA_HOME=#{ENV["JAVA_HOME"]}")
Rails.logger.info("\nJRUBY_OPTS=#{ENV["JRUBY_OPTS"]}\n")

# FIXME: Consider raising an informative error if this constant is not set properly.

require "form_tag_helper_extensions.rb"
require "active_record_associations_extensions"

Date::DATE_FORMATS.merge! \
  :standard  => '%B %d, %Y @ %I:%M %p',
  :stub      => '%B %d',
  :stub_with_short_months      => '%b %d',
  :stub_with_short_months_and_year => '%b %d %y',
  :time_only => '%I:%M %p',
  :plain     => '%B %d %I:%M %p',
  :mdy       => '%B %d, %Y',
  :human_mdy => '%A, %B %d, %Y',
  :human_mdy_short => '%a %b %d, %Y',
  :md        => '%b %d',
  :my        => '%B %Y',
  :simple    => '%m/%d/%Y',
  :simple_with_time    => '%m/%d/%Y @ %I:%M %p',
  :unix      => '%m%d',
  :ss_date   => '%d %b.'

Date::DATE_FORMATS.merge! :md => "%B %d"

AdapterName = ActiveRecord::Base.connection.adapter_name

OracleAdapter = AdapterName == 'OracleEnhanced'
PostgreSQLAdapter = AdapterName == 'PostgreSQL'
MsSQLAdapter = AdapterName.match /mssql/i
MySQLAdapter = false

# avoid defining this twice, so test if MSSQL or Oracle which define it
if MsSQLAdapter || OracleAdapter
  # used to reject certain fields or flag them for special handling according to database driver
  # for example reserved word field names in oracle need to be quotes AND uppercase, but this
  # will break postgres queries.  Sometimes it is possible to just not select them if they are not used
  # in the operations in question.
  DATABASE_RESERVED_WORDS = ["DEFAULT"]
else
  DATABASE_RESERVED_WORDS = []
end

PortfolioSupport = OracleAdapter

RPMTRUE = ( PostgreSQLAdapter  ? true : ( 1 ) )
RPMFALSE = ( PostgreSQLAdapter ? false : ( 0 ) )

PROCEDURE_COLUMN = MsSQLAdapter ? '"procedure"' : 'procedure'
DB_STRLEN = MsSQLAdapter ? 'DATALENGTH' : 'LENGTH'

# DATE_NOW variable is introduced to resolve now() equivalent operation w.r.t.
# database adpater used.
if PostgreSQLAdapter
  DATE_NOW = "now()"
elsif OracleAdapter
  DATE_NOW = "SYSDATE"
else
  DATE_NOW = "{fn NOW()}"
end

# make customizations to the wkhtmltopdf exepath
# created during the install process.
wicked_pdf_config_file = File.join(Rails.root, 'config', 'wicked_pdf_config.rb')
if File.exist?(wicked_pdf_config_file)
  load wicked_pdf_config_file
else
  # if there is no user defined wicked_pdf_config_file.rb, then load the default
  load File.join(Rails.root, 'config', 'wicked_pdf_config.default.rb')
end

#
# RJ: 06/27
# This is required to be reset again
# because on tomcat, GEM_HOME is set to something inside of the war
# The gems there are not sufficient for automation to run
# Automation fails in that case. On the other hand
# since we already ship jruby, we leverage all gems from there
if JRUBY_VERSION == '1.6.8'
  ENV['GEM_HOME']=File.join("#{ENV['JRUBY_HOME']}", 'lib', 'ruby', 'gems', '1.8')
else
  ENV['GEM_HOME']=File.join("#{ENV['JRUBY_HOME']}", 'lib', 'ruby', 'gems', 'shared')
end

#require 'java'

#import java.lang.management.ManagementFactory
#puts "Enabling GC verbose logging...."
#ManagementFactory.getMemoryMXBean.setVerbose(true)
